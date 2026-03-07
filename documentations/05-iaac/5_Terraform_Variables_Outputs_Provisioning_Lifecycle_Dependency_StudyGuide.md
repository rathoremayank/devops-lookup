# Terraform Variables, Outputs, Provisioning Patterns, Lifecycle Management & Dependency Handling

## Table of Contents

- [1. Introduction](#1-introduction)
  - [1.1 Overview of Topic](#11-overview-of-topic)
  - [1.2 Real-World Production Use Cases](#12-real-world-production-use-cases)
  - [1.3 Cloud Architecture Integration](#13-cloud-architecture-integration)
- [2. Foundational Concepts](#2-foundational-concepts)
  - [2.1 Architecture Fundamentals](#21-architecture-fundamentals)
  - [2.2 Important DevOps Principles](#22-important-devops-principles)
  - [2.3 Best Practices for Production Environments](#23-best-practices-for-production-environments)
  - [2.4 Common Misunderstandings & Pitfalls](#24-common-misunderstandings--pitfalls)
- [3. Terraform Variables and Outputs](#3-terraform-variables-and-outputs)
- [4. Provisioning Patterns](#4-provisioning-patterns)
- [5. Lifecycle Management](#5-lifecycle-management)
- [6. Dependency Handling](#6-dependency-handling)
- [7. Hands-on Scenarios](#7-hands-on-scenarios)
- [8. Interview Questions](#8-interview-questions)

---

## 1. Introduction

### 1.1 Overview of Topic

Terraform's power in infrastructure-as-code (IaC) stems from its ability to manage infrastructure declaratively while maintaining complex interdependencies, variable configurations, and resource lifecycle policies. The four pillars covered in this study guide—**Variables and Outputs**, **Provisioning Patterns**, **Lifecycle Management**, and **Dependency Handling**—form the backbone of enterprise-grade Terraform implementations.

For senior DevOps engineers, mastering these concepts means moving beyond basic resource creation to designing scalable, reusable, and maintainable infrastructure code that handles production constraints: multi-environment deployments, zero-downtime updates, disaster recovery procedures, and cost optimization.

**Key capabilities enabled by these features:**

- **Dynamic infrastructure adaptation** through variables, conditionals, and loops
- **Output-driven architecture** for cross-stack dependencies and integration patterns
- **Safe resource mutation** through lifecycle management
- **Explicit control over resource ordering** and creation/destruction sequencing
- **Reusability across teams and organizations** via modular, configurable code

This study guide assumes you understand:
- Core Terraform syntax and HCL fundamentals
- State management and its role in infrastructure management
- Basic AWS/cloud provider concepts
- DevOps CI/CD pipelines and deployment strategies

### 1.2 Real-World Production Use Cases

#### Multi-Environment Infrastructure Deployment
Organizations typically maintain 3-5 environments: **dev**, **staging**, **uat**, **production**, and sometimes **disaster-recovery**. Without proper variables and outputs:
- Code duplication becomes unmanageable
- Drift between environments creates unpredictable failures
- Rolling back changes across environments becomes error-prone

A well-structured variable system allows a **single codebase** to deploy across all environments with environment-specific values sourced from `.tfvars` files or remote configuration systems.

#### Blue-Green and Canary Deployments
Production applications require zero-downtime deployments. Using `create_before_destroy` lifecycle policies ensures:
- New infrastructure provisions before old infrastructure terminates
- DNS/load balancer cutover happens with both infrastructure versions available
- Instant rollback capability if issues are detected
- Minimal recovery time objective (RTO) and recovery point objective (RPO) impact

#### Gradual Infrastructure Evolution
Imagine scaling a fleet of EC2 instances from on-premises managed servers to containerized workloads on EKS. Using `for_each` and conditional expressions allows:
- Gradual resource replacement rather than big-bang migrations
- Side-by-side execution of legacy and new systems
- A/B testing of infrastructure changes at scale
- Measured blast radius of changes

#### Cost Optimization and Tagging at Scale
Large organizations with hundreds or thousands of resources need automatic tagging, lifecycle expiry, and smart deprovisioning. Variables combined with `merge()` and `dynamic` blocks enable:
- Centralized tagging strategies enforced across all resources
- Automatic cost allocation and chargeback models
- Automated cleanup of dev/test resources post-deployment
- Compliance and audit trail requirements

#### Disaster Recovery automation
When production infrastructure fails, recovery is driven by Terraform state and output values:
- Outputs provide failover targets (RDS read replicas, standby regions)
- Explicit dependencies ensure failover infrastructure exists before primary is removed
- Lifecycle policies prevent accidental deletion of critical resources
- Conditional provisioning activates DR resources only when needed

### 1.3 Cloud Architecture Integration

Modern cloud architectures are not monolithic Terraform roots—they're composed of multiple layers, each managed by specialized teams:

```
┌─────────────────────────────────────────────────┐
│  Platform Engineering (Terraform Root Modules)  │
├─────────────────────────────────────────────────┤
│  ◉ VPC & Networking Layer                       │
│  ◉ Security Groups & NACLs                      │
│  ◉ IAM Roles & Policies                         │
│  ◉ Shared Services (DNS, logging, monitoring)   │
│                                                  │
│  Outputs: VPC ID, Subnet IDs, Role ARNs        │
└─────────────────────────────────────────────────┘
                        ↓
                  (Outputs consumed)
                        ↓
┌─────────────────────────────────────────────────┐
│  Application Infrastructure (Child Modules)     │
├─────────────────────────────────────────────────┤
│  ◉ Application servers (EC2/ECS/EKS)           │
│  ◉ Databases (RDS, DynamoDB)                    │
│  ◉ Load Balancers & Auto Scaling                │
│  ◉ Message queues & event streams               │
│                                                  │
│  Variables: Environment, region, instance count │
│  Outputs: Service endpoints, DNS names          │
└─────────────────────────────────────────────────┘
                        ↓
                  (Outputs consumed)
                        ↓
┌─────────────────────────────────────────────────┐
│  Observability Layer (Monitoring Config)        │
├─────────────────────────────────────────────────┤
│  ◉ CloudWatch dashboards                        │
│  ◉ Log aggregation configurations               │
│  ◉ Alert rules & SNS topics                     │
│  ◉ APM instrumentation                          │
└─────────────────────────────────────────────────┘
```

**Why this matters for senior engineers:**
- Each layer has a **stable API** (inputs as variables, outputs as consumed values)
- Changes in one layer propagate safely through dependency chains
- Lifecycle policies protect critical infrastructure from accidental deletions
- Provisioning patterns enable gradual infrastructure evolution without monolithic deploys

---

## 2. Foundational Concepts

### 2.1 Architecture Fundamentals

#### The Infrastructure Declaration Model

Terraform operates on a **declarative** model fundamentally different from imperative automation (shell scripts, Ansible playbooks). Understanding this distinction is critical:

| Aspect | Imperative (Procedural) | Declarative (Terraform) |
|--------|------------------------|-----------------------|
| **What you write** | How to reach desired state | What the final state should be |
| **State tracking** | Manual, error-prone | Managed by Terraform state file |
| **Idempotency** | Developer responsibility | Built-in by design |
| **Variables** | Used in control flow | Describe infrastructure parameters |
| **Change detection** | Not automatic | Plan phase reveals exact changes |
| **Rollback capability** | Complex, script-dependent | State version + plan recreation |

**Example - Imperative vs. Declarative:**

*Imperative approach (Ansible):*
```yaml
- name: Create EC2 instance if not exists
  ec2:
    instance_type: t3.medium
    # Must manually check if instance exists
    # Handle failure scenarios
```

*Declarative approach (Terraform):*
```hcl
resource "aws_instance" "app" {
  instance_type = "t3.medium"
  # Terraform automatically detects drift
  # Naturally handles creates, updates, deletes
}
```

#### The Immutable Infrastructure Principle

Modern DevOps practices favor **immutable infrastructure**:
- Servers are never modified post-deployment (no SSH configuration)
- When updates are needed, new infrastructure is provisioned and old is decommissioned
- Configuration is baked into AMIs/container images, not applied at runtime

**Lifecycle management** directly supports this principle through:
- `create_before_destroy` ensuring zero-downtime updates
- `prevent_destroy` protecting critical resources
- Graceful deprovisioning with proper ordering

#### The Graph Data Structure

Every Terraform configuration is internally represented as a **directed acyclic graph (DAG)**:

```
┌─────────────────┐
│  AWS VPC        │
│  (aws_vpc.main) │
└────────┬────────┘
         │
    ┌────┴──────────┬──────────────────┐
    │               │                  │
┌───▼──────┐  ┌────▼──────┐  ┌──────▼──┐
│ Subnet 1 │  │ Subnet 2   │  │ Route   │
│(depends) │  │ (depends)  │  │ Table   │
└───┬──────┘  └────┬───────┘  └──┬──────┘
    │              │             │
    └──────────┬───┘             │
               │                 │
          ┌────▼─────────────────▼──┐
          │  Security Group         │
          │  (depends on Subnets)   │
          │  (depends on VPC)       │
          └────┬────────────────────┘
               │
          ┌────▼────────────────────┐
          │  EC2 Instance           │
          │  (depends on Security)  │
          │  (depends on Subnet)    │
          └─────────────────────────┘
```

**Why this matters:**
- Terraform parallelizes resources with no dependencies
- Explicit dependencies force serialization when necessary
- Cycle detection prevents deadlocks (Terraform fails if cycles exist)
- Plan phase uses the graph to determine exact ordering and changes

### 2.2 Important DevOps Principles

#### Configuration as Code (CaC) vs. Infrastructure as Code (IaC)

These terms are often conflated but serve different purposes:

| Aspect | IaC (Terraform) | CaC (Ansible/Chef) |
|--------|---------------|--------------------|
| **Focus** | Infrastructure provisioning | Runtime configuration |
| **Scope** | VMs, networks, storage | Application config, OS state |
| **State** | Centralized state file | Distributed or none |
| **Idempotency** | Built-in by default | Must be implemented |
| **Example** | Create VPC, subnets, security groups | Install packages, configure systemd |

**Senior engineers recognize:** Terraform and CaC tools are complementary. The optimal pipeline uses:
1. **Terraform** to provision infrastructure resources
2. **CaC tools** (Ansible, cloud-init) to configure instances post-provisioning
3. **Container images** (Packer + CaC) to embed configuration into immutable artifacts

#### The Principle of Least Astonishment

Infrastructure code should be:
- **Readable**: Future maintainers (including yourself in 6 months) understand intent
- **Predictable**: Variables and outputs have clear contracts
- **Explicit**: Dependencies are visible, not hidden in resource references
- **Fail-safe**: Lifecycle policies prevent accidental destructive operations

#### DRY (Don't Repeat Yourself) in Infrastructure

Repetition creates version skew and maintenance burden:
- **Local values** (`locals`) eliminate computed duplication
- **Dynamic blocks** avoid resource block repetition
- **Modules** enable code reuse across projects
- **Variables + for_each** handle scaling without copy-paste

#### The Single Responsibility Principle for Modules

Each Terraform module should have one clear purpose:
- **Networking module**: VPC, subnets, route tables, NACLs
- **security module**: Security groups, IAM roles (for infrastructure)
- **Application module**: EC2/ECS/EKS, autoscaling, load balancers

This enables teams to independently develop, test, and version modules.

### 2.3 Best Practices for Production Environments

#### Variable Validation & Constraints

Never trust user input. Variables should validate types, ranges, and format:

```hcl
variable "instance_count" {
  type        = number
  description = "Number of application instances"
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 100
    error_message = "Instance count must be between 1 and 100."
  }
}

variable "environment" {
  type = string
  description = "Deployment environment"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

#### Sensitive Data Handling

Production environments contain secrets: database passwords, API keys, TLS certificates. Best practices:

1. **Never** commit secrets to Git
2. Use external secret management:
   - AWS Secrets Manager
   - HashiCorp Vault
   - Azure Key Vault
3. Mark sensitive variables explicitly:
   ```hcl
   variable "db_password" {
     type      = string
     sensitive = true
     description = "RDS master password"
   }
   ```
4. Use output sensitivity to prevent accidental exposure:
   ```hcl
   output "rds_endpoint" {
     value     = aws_db_instance.main.endpoint
     sensitive = false
   }
   
   output "db_password" {
     value     = random_password.db.result
     sensitive = true  # Prevents display in plan/apply
   }
   ```

#### Provider Versioning and Constraints

Always pin provider versions in production:

```hcl
terraform {
  required_version = ">= 1.0, < 2.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"  # Allows 5.x but not 6.x
    }
  }
}
```

Unversioned providers can break due to:
- Provider API changes
- New defaults that alter resource behavior
- Deprecated arguments removal

#### State File Security

The state file is sensitive data:

1. **Remote state**: Never local state in production
   ```hcl
   terraform {
     backend "s3" {
       bucket         = "company-terraform-state"
       key            = "prod/terraform.tfstate"
       region         = "us-east-1"
       encrypt        = true
       dynamodb_table = "terraform-locks"
     }
   }
   ```

2. **Encryption at rest**: S3 bucket encryption, AWS KMS
3. **Access control**: IAM policies restrict who can read/modify state
4. **Locking**: DynamoDB prevents concurrent modifications
5. **Backup**: Enable versioning on state bucket

#### Modular Architecture for Scale

For organizations managing 100+ resources per environment:

```
terraform/
├── modules/
│   ├── networking/
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   └── versions.tf
│   ├── compute/
│   ├── database/
│   └── monitoring/
├── environments/
│   ├── dev/
│   │   ├── terraform.tfvars
│   │   └── main.tf (calls modules)
│   ├── staging/
│   ├── prod/
│   └── dr/
└── shared/
    └── variables.tf (env-agnostic defaults)
```

This structure enables:
- Parallel work by different teams
- Environment-specific overrides via `.tfvars`
- Module version pinning for stability
- Clear separation of concerns

#### Testing Infrastructure Code

Senior engineers know: untested infrastructure code is risk. Strategies:

1. **Static validation**: `terraform validate`, `terraform fmt`
2. **Linting**: `tflint` for best practices
3. **Unit testing**: `terratest` for module behavior
4. **Integration testing**: Deploy test stacks before production
5. **Policy as Code**: `OPA/Rego` or `Sentinel` for compliance

### 2.4 Common Misunderstandings & Pitfalls

#### Misunderstanding #1: Implicit Dependencies are Sufficient

**False assumption**: "Terraform will figure out the dependency order from my resource references."

**Reality**: Terraform *does* detect implicit dependencies but this creates several problems:

1. **Brittle code**: Refactoring variable names breaks implicit dependencies
2. **Reduced parallelization**: Unnecessary dependencies slow plans/applies
3. **Unclear intent**: Future engineers don't know which dependencies are critical vs. accidental
4. **Testing difficulty**: Hard to mock dependencies in tests

**Best practice**: Use explicit `depends_on` when business logic (not resource attributes) dictates ordering.

#### Misunderstanding #2: lifecycle Rules Apply Globally

**False assumption**: "I set `create_before_destroy` once, and all updates follow this pattern."

**Reality**: Lifecycle rules are **resource-specific**:

```hcl
resource "aws_instance" "app_v1" {
  # This instance uses create_before_destroy
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_db_instance" "main" {
  # This instance uses ignore_changes (no create_before_destroy)
  # Different strategy for stateful resources
  lifecycle {
    ignore_changes = [parameter_group_name]
  }
}
```

Different resource types need different strategies. Stateless resources (servers) use create_before_destroy. Stateful resources (databases) use ignore_changes or prevent_destroy.

#### Misunderstanding #3: for_each vs. count Doesn't Matter

**False assumption**: "I can use either for_each or count—they're the same."

**Reality**: They have fundamentally different behavior:

| Aspect | `count` | `for_each` |
|--------|---------|-----------|
| **Indexing** | Numeric indices (0, 1, 2...) | String keys from map/set |
| **Resource addressing** | `aws_instance.app[0]` | `aws_instance.app["prod"]` |
| **Stability** | Fragile—removing item 0 shifts all indices | Stable—keys don't shift |
| **Readability** | Less clear what each iteration represents | Clear semantic meaning |
| **Flexibility** | Can't iterate over maps easily | Natural for map/set iteration |

**Best practice**: Use `for_each` except when the collection size must be completely dynamic and you're okay with state recreation on removals.

#### Misunderstanding #4: Outputs Have No Impact on State

**False assumption**: "Outputs are just display—they don't affect the actual state."

**Reality**: Outputs have critical implications:

1. **Cross-module data sharing**: Outputs are the **only** way child modules return data to parent
2. **State coupling**: Output values are stored in state, enabling later consumption
3. **Sensitive data exposure**: Outputs are visible in state files
4. **Performance**: Sensitive outputs are marked to prevent display, but still stored

#### Misunderstanding #5: Variables are Just for User Input

**False assumption**: "Variables are only for terraform.tfvars—they're not part of the logic."

**Reality**: Variables are fundamental to dynamic infrastructure:

```hcl
# Variables participate in conditionals
resource "aws_db_instance" "main" {
  count             = var.enable_database ? 1 : 0  # Conditional existence
  allocated_storage = var.environment == "prod" ? 100 : 20  # Conditional sizing
  multi_az          = var.environment == "prod"  # Conditional redundancy
}

# Variables enable computed logic
locals {
  instance_type = {
    dev  = "t3.micro"
    staging = "t3.small"
    prod = "m5.xlarge"
  }[var.environment]
}

resource "aws_instance" "app" {
  instance_type = local.instance_type
}
```

#### Misunderstanding #6: Provisioners are the Right Tool for Configuration

**False assumption**: "I'll use provisioners to configure applications post-provisioning."

**Reality**: Provisioners are an **anti-pattern** in Terraform:

1. **State management**: Provisioner output isn't tracked; failures leave ambiguous state
2. **Debugging**: Hard to troubleshoot provisioner failures in production
3. **Idempotency**: Provisioners are not idempotent by default
4. **Dependency clarity**: Creating resources doesn't guarantee provisioner execution order

**Best practice**: 
- Use `cloud-init` / `user_data` for basic OS-level configuration (preferred)
- Use external configuration management (Ansible) for complex setups
- Use container images (Packer) with embedded configuration (most robust)

---

## 3. Terraform Variables and Outputs

### 3.1 Input Variables

#### Textual Deep Dive

**Architecture Role:**
Input variables are the primary mechanism for parameterizing Terraform configurations, enabling the same codebase to be deployed across different environments, regions, and contexts without modification. They form the **contract** between configuration authors and infrastructure operators.

In a typical enterprise setup:
- Platform engineers define variables in modules
- DevOps teams provide values via `.tfvars` files or environment variables
- CI/CD pipelines inject values from secrets management systems (Vault, AWS Secrets Manager)

**Internal Working Mechanism:**

Variables undergo a multi-stage processing pipeline:

```
Input Sources (Priority Order)
├── 1. Command-line flags (-var "key=value")
├── 2. Environment variables (TF_VAR_*)
├── 3. .tfvars files (terraform.tfvars, custom.tfvars)
├── 4. .tfvars.json files
└── 5. Variable default values
       │
       ▼
Variable Validation
├── Type checking (string, number, bool, list, map, object, set, tuple)
├── Custom validation blocks
└── Constraint enforcement
       │
       ▼
Variable Interpolation
├── HCL expression evaluation
├── Function resolution
└── Reference resolution (locals, data sources)
       │
       ▼
Plan Phase
├── Variable values locked for consistency
└── Used in resource definitions and conditionals
```

**Type System Details:**

Terraform's type system is richer than many assume:

```hcl
# Primitive types
variable "instance_type" {
  type = string  # "t3.medium"
}

variable "instance_count" {
  type = number  # 5, 3.14
}

variable "enable_monitoring" {
  type = bool  # true/false
}

# Collection types
variable "availability_zones" {
  type = list(string)  # ["us-east-1a", "us-east-1b"]
}

variable "tags" {
  type = map(string)  # { Name = "prod", Env = "production" }
}

# Complex types
variable "instance_config" {
  type = object({
    name         = string
    instance_type = string
    tags         = map(string)
  })
}

variable "app_tiers" {
  type = map(object({
    instance_count = number
    instance_type  = string
  }))
}

variable "mixed_data" {
  type = tuple([string, number, bool])  # ["web", 5, true]
}

# Dynamic type (accept anything)
variable "flexible_config" {
  type = any
}
```

**Variable Precedence (Most to Least Specific):**

When the same variable is defined in multiple sources, Terraform follows strict precedence:

1. **CLI flags** (`terraform apply -var 'instance_type=m5.large'`)
2. **Environment variables** (`export TF_VAR_instance_type=m5.large`)
3. **`.tfvars` files** (automatically loaded: `terraform.tfvars`, `.terraform.tfvars`)
4. **`.tfvars.json` files** (JSON-formatted variables)
5. **Variable default values** (in variable definition)

This enables CI/CD pipelines to safely override environment-specific values without modifying source files.

**Production Usage Patterns:**

In enterprise deployments, variables follow these patterns:

1. **Environment isolation via .tfvars:**
   ```
   terraform/
   ├── main.tf (shared code, references variables)
   ├── environments/
   │   ├── dev.tfvars
   │   ├── staging.tfvars
   │   └── prod.tfvars
   ```

2. **Registry/workspace patterns:**
   ```bash
   # Different .tfvars per workspace
   terraform workspace select dev
   terraform apply -var-file="dev.tfvars"
   
   terraform workspace select prod
   terraform apply -var-file="prod.tfvars"
   ```

3. **CI/CD pipeline variable injection:**
   ```bash
   # GitLab CI, GitHub Actions, Jenkins
   terraform plan \
     -var "environment=$CI_ENVIRONMENT_NAME" \
     -var "app_version=$CI_COMMIT_SHA" \
     -var-file="environments/${CI_ENVIRONMENT_NAME}.tfvars"
   ```

**DevOps Best Practices:**

1. **Always validate type and constraints:**
   ```hcl
   variable "replicas" {
     type = number
     description = "Number of application replicas"
     
     validation {
       condition     = var.replicas >= 2 && var.replicas <= 1000
       error_message = "Replicas must be between 2 and 1000."
     }
   }
   ```

2. **Provide sensible defaults for optional parameters:**
   ```hcl
   variable "tags" {
     type = map(string)
     default = {
       ManagedBy = "Terraform"
       Team      = "Platform"
     }
     description = "Common tags for all resources"
   }
   ```

3. **Use nullable for truly optional parameters:**
   ```hcl
   variable "custom_domain" {
     type    = string
     default = null  # Domain is optional
     nullable = true
     description = "Custom domain, leave null for default"
   }
   ```

4. **Document clearly with descriptions:**
   ```hcl
   variable "environment" {
     type        = string
     description = "Deployment environment (dev, staging, prod)"
     
     validation {
       condition = contains(["dev", "staging", "prod"], var.environment)
       error_message = "Must be dev, staging, or prod."
     }
   }
   ```

**Common Pitfalls:**

1. **Using environment variables for secrets directly:**
   ```hcl
   # ❌ WRONG - Exposes secrets in process listings
   export TF_VAR_db_password="SuperSecretPassword123"
   terraform apply
   
   # ✅ CORRECT - Use secrets management
   export TF_VAR_db_password=$(aws secretsmanager get-secret-value \
     --secret-id rds/prod/password --query SecretString)
   terraform apply
   ```

2. **Not validating input format:**
   ```hcl
   # ❌ WRONG - Accepts any string
   variable "vpc_cidr" {
     type = string
   }
   
   # ✅ CORRECT - Validates CIDR format
   variable "vpc_cidr" {
     type = string
     
     validation {
       condition     = can(cidrhost(var.vpc_cidr, 0))
       error_message = "Must be valid CIDR block."
     }
   }
   ```

3. **Not using types in modules:**
   ```hcl
   # ❌ WRONG - Unclear contract
   variable "config" {
     type = any
   }
   
   # ✅ CORRECT - Explicit contract
   variable "config" {
     type = object({
       name         = string
       environment  = string
       instance_type = string
     })
   }
   ```

#### Practical Code Examples

**Example 1: Multi-environment deployment:**

```hcl
# variables.tf
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
  default     = 1
  description = "Number of application instances"
  
  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 100
    error_message = "Instance count must be 1-100."
  }
}

variable "tags" {
  type = map(string)
  default = {
    ManagedBy = "Terraform"
  }
  description = "Common tags for resources"
}

# main.tf
locals {
  instance_type = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "m5.xlarge"
  }[var.environment]
  
  instance_count = var.environment == "prod" ? max(3, var.instance_count) : var.instance_count
  
  tags = merge(
    var.tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  )
}

resource "aws_instance" "app" {
  count         = local.instance_count
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = local.instance_type
  
  subnet_id = aws_subnet.app[count.index % length(aws_subnet.app)].id
  
  tags = merge(
    local.tags,
    {
      Name = "${var.environment}-app-${count.index + 1}"
    }
  )
}

# dev.tfvars
environment    = "dev"
instance_count = 1

# prod.tfvars
environment    = "prod"
instance_count = 5

# CLI deployment
terraform apply -var-file="prod.tfvars"
```

**Example 2: Complex object variables for application configuration:**

```hcl
variable "application_config" {
  type = object({
    name = string
    tiers = map(object({
      instance_type  = string
      instance_count = number
      allocate_public_ip = bool
    }))
    database = object({
      engine          = string
      version         = string
      allocated_storage = number
      backup_retention = number
    })
    monitoring = object({
      enabled         = bool
      detailed_monitoring = bool
      log_retention   = number
    })
  })
  
  description = "Complete application infrastructure configuration"
  
  validation {
    condition = contains(["postgres", "mysql"], var.application_config.database.engine)
    error_message = "Database engine must be postgres or mysql."
  }
}

# Usage
locals {
  app = var.application_config
}

resource "aws_instance" "web" {
  for_each      = local.app.tiers
  instance_type = each.value.instance_type
  count         = each.value.instance_count
}

resource "aws_db_instance" "main" {
  engine              = local.app.database.engine
  engine_version      = local.app.database.version
  allocated_storage   = local.app.database.allocated_storage
  backup_retention_period = local.app.database.backup_retention
}
```

---

### 3.2 Local Values

#### Textual Deep Dive

**Architecture Role:**
Local values (`locals`) are computed, reusable values scoped to a module. Unlike variables (which accept external input), locals are purely internal to the module and cannot be overridden from outside. They serve as intermediate calculations, reducing repetition and improving readability.

**Internal Working Mechanism:**

Locals are evaluated in a single pass during the plan phase:

```
Variable Resolution
       │
       ▼
Local Value Evaluation
├── Expression evaluation order (dependencies resolved)
├── Type inference from assigned values
├── Scope: module-level (not accessible outside)
│
       ▼
Reference Resolution in Resources/Outputs
├── Locals referenced as local.<name>
└── Immutable during apply phase
```

**Production Usage Patterns:**

1. **Computed defaults based on variables:**
   ```hcl
   variable "environment" {
     type = string
   }
   
   locals {
     # Computed based on environment
     instance_type = var.environment == "prod" ? "m5.xlarge" : "t3.micro"
     availability_zones = var.environment == "prod" ? 3 : 2
     backup_retention   = var.environment == "prod" ? 30 : 7
   }
   ```

2. **Tag consolidation:**
   ```hcl
   locals {
     common_tags = {
       Project      = var.project_name
       Environment  = var.environment
       CostCenter   = var.cost_center
       ManagedBy    = "Terraform"
       CreatedAt    = timestamp()
     }
   }
   
   resource "aws_instance" "app" {
     tags = merge(local.common_tags, { Name = "app-server" })
   }
   ```

3. **Complex naming conventions:**
   ```hcl
   locals {
     # Derived naming for resource consistency
     name_prefix = "${var.organization}-${var.environment}-${var.region}"
     
     resource_names = {
       vpc             = "${local.name_prefix}-vpc"
       subnets         = "${local.name_prefix}-subnet"
       security_groups = "${local.name_prefix}-sg"
       rds             = "${local.name_prefix}-rds"
     }
   }
   ```

**DevOps Best Practices:**

1. **Use locals for complex logic instead of repeating in resources:**
   ```hcl
   # ❌ WRONG - Logic repeated in multiple resources
   resource "aws_instance" "web" {
     instance_type = var.environment == "prod" && var.enable_high_performance ? "m5.2xlarge" : "t3.small"
   }
   
   resource "aws_instance" "app" {
     instance_type = var.environment == "prod" && var.enable_high_performance ? "m5.2xlarge" : "t3.small"
   }
   
   # ✅ CORRECT - Logic in locals
   locals {
     instance_type = var.environment == "prod" && var.enable_high_performance ? "m5.2xlarge" : "t3.small"
   }
   
   resource "aws_instance" "web" {
     instance_type = local.instance_type
   }
   ```

2. **Group related locals for clarity:**
   ```hcl
   locals {
     # Network configuration
     network = {
       vpc_cidr            = "10.0.0.0/16"
       availability_zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
       private_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
       public_subnet_cidrs  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
     }
     
     # Application configuration
     application = {
       port           = 8080
       protocol       = "HTTP"
       health_check   = "/health"
       timeout_seconds = 30
     }
   }
   ```

**Common Pitfalls:**

1. **Accessing locals outside their module scope:**
   ```hcl
   # ❌ WRONG - Locals are not exportable
   # module/web/main.tf
   locals {
     instance_type = "t3.medium"
   }
   
   # main.tf (parent)
   module "web_app" {
     source = "./modules/web"
   }
   
   # This will fail - can't access module.web_app.local.instance_type
   
   # ✅ CORRECT - Use outputs to expose computed values
   # module/web/outputs.tf
   output "instance_type" {
     value = local.instance_type
   }
   ```

2. **Using locals for values that should be variables:**
   ```hcl
   # ❌ WRONG - Hardcodes environment-specific values
   locals {
     db_master_password = "FixedPassword123"
   }
   
   # ✅ CORRECT - Use variables for external input
   variable "db_master_password" {
     type      = string
     sensitive = true
   }
   ```

#### Practical Code Examples

**Example: Complex infrastructure with locals:**

```hcl
variable "environment" {
  type = string
}

variable "region" {
  type = string
}

variable "application_name" {
  type = string
}

locals {
  # Naming convention
  environment_prefix = "${var.application_name}-${var.environment}"
  
  # Multi-tier resource names
  resource_names = {
    for tier in ["web", "app", "data"] :
    tier => "${local.environment_prefix}-${tier}"
  }
  
  # Environment-specific configurations
  config = {
    dev = {
      instance_type      = "t3.micro"
      db_storage         = 20
      enable_monitoring  = false
      replicas           = 1
    }
    staging = {
      instance_type      = "t3.small"
      db_storage         = 50
      enable_monitoring  = true
      replicas           = 2
    }
    prod = {
      instance_type      = "m5.large"
      db_storage         = 500
      enable_monitoring  = true
      replicas           = 3
    }
  }[var.environment]
  
  # Consolidated tags
  tags = {
    Application = var.application_name
    Environment = var.environment
    Region      = var.region
    ManagedBy   = "Terraform"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  }
}

# Usage in resources
resource "aws_instance" "web" {
  instance_type = local.config.instance_type
  
  tags = merge(
    local.tags,
    { Name = "${local.resource_names.web}-instance" }
  )
}

resource "aws_db_instance" "main" {
  allocated_storage = local.config.db_storage
  
  tags = merge(
    local.tags,
    { Name = "${local.resource_names.data}-database" }
  )
}
```

---

### 3.3 Variables (.tfvars) Files

#### Textual Deep Dive

**Architecture Role:**
`.tfvars` files separate infrastructure configuration (values) from infrastructure code (logic). They enable a single Terraform codebase to be deployed across environments, regions, and organizations without source code modification, supporting DevOps best practices like code review, version control, and auditability.

**File Format:**

Terraform accepts `.tfvars` files in two formats:

```hcl
# HCL format (terraform.tfvars)
environment    = "production"
instance_count = 5
enable_backup  = true

tags = {
  Environment = "production"
  CostCenter  = "engineering"
}

database_config = {
  engine     = "postgres"
  version    = "14.7"
  storage    = 100
  backup_days = 30
}
```

```json
// JSON format (terraform.tfvars.json)
{
  "environment": "production",
  "instance_count": 5,
  "enable_backup": true,
  "tags": {
    "Environment": "production",
    "CostCenter": "engineering"
  },
  "database_config": {
    "engine": "postgres",
    "version": "14.7",
    "storage": 100,
    "backup_days": 30
  }
}
```

**Loading Behavior:**

Terraform automatically loads variables in this order:

1. `terraform.tfvars` (if exists)
2. `terraform.tfvars.json` (if exists)
3. `.terraform.auto.tfvars` (automatically loaded)
4. `.terraform.auto.tfvars.json` (automatically loaded)
5. Files specified via `-var-file` flag (in order provided)

**Production Usage Patterns:**

1. **Environment-specific .tfvars structure:**
   ```
   terraform/
   ├── main.tf (shared infrastructure code)
   ├── variables.tf (variable definitions)
   ├── outputs.tf
   ├── environments/
   │   ├── dev.tfvars
   │   ├── staging.tfvars
   │   └── prod.tfvars
   └── regions/
       ├── us-east-1.tfvars
       ├── us-west-2.tfvars
       └── eu-west-1.tfvars
   ```

2. **Layered .tfvars approach (base + overrides):**
   ```bash
   # Apply base configuration + environment overrides
   terraform apply \
     -var-file="common.tfvars" \
     -var-file="environments/prod.tfvars" \
     -var-file="regions/us-east-1.tfvars"
   ```

3. **CI/CD pipeline variable injection:**
   ```yaml
   # GitHub Actions example
   - name: Plan Terraform
     run: |
       terraform plan \
         -var-file="environments/${{ github.ref_name }}.tfvars" \
         -var="build_number=${{ github.run_number }}" \
         -out=tfplan
   ```

**DevOps Best Practices:**

1. **Use .gitignore to prevent secret leakage:**
   ```gitignore
   # .gitignore
   terraform.tfvars
   terraform.tfvars.json
   .terraform.auto.tfvars
   .terraform.auto.tfvars.json
   *.local.tfvars  # Local development overrides
   tfplan          # Binary plan files
   ```

2. **Include non-secret, environment-agnostic values in repo:**
   ```hcl
   # common.tfvars - SAFE TO COMMIT
   enable_detailed_monitoring = true
   backup_retention_days      = 30
   default_tags = {
     ManagedBy = "Terraform"
     Project   = "Platform"
   }
   ```

3. **Manage secrets separately from .tfvars:**
   ```bash
   # ✅ CORRECT - Pull secrets at runtime
   terraform apply \
     -var-file="environments/prod.tfvars" \
     -var "db_password=$(aws secretsmanager get-secret-value \
       --secret-id rds/prod/master-password \
       --query SecretString --output text)"
   ```

4. **Document .tfvars structure:**
   ```hcl
   # environments/prod.tfvars example

   # Deployment and sizing
   environment    = "production"
   region         = "us-east-1"
   instance_count = 5
   
   # Database configuration
   database_engine         = "postgres"
   database_version        = "14.7"
   database_allocated_storage = 500
   database_backup_retention_days = 30
   
   # Application configuration
   app_port     = 8080
   app_health_check_path = "/health"
   
   # Tagging
   tags = {
     Environment = "production"
     CostCenter  = "engineering"
     Compliance  = "sox"
   }
   ```

**Common Pitfalls:**

1. **Committing secrets to .tfvars:**
   ```hcl
   # ❌ WRONG - Secret in version control
   # prod.tfvars
   db_master_password = "SuperSecret123"
   api_key            = "sk-1234567890abcdef"
   
   # ✅ CORRECT - Reference external secrets
   # prod.tfvars
   database_password_arn = "arn:aws:secretsmanager:us-east-1:123456789:secret:rds/prod/password"
   ```

2. **Not validating .tfvars values in Terraform code:**
   ```hcl
   # ❌ WRONG - No validation
   variable "instance_count" {
     type = number
   }
   
   # ✅ CORRECT - Validate in variable definition
   variable "instance_count" {
     type = number
     validation {
       condition     = var.instance_count >= 1 && var.instance_count <= 100
       error_message = "Instance count must be 1-100."
     }
   }
   ```

3. **Overcomplicating .tfvars with logic:**
   ```hcl
   # ❌ WRONG - Logic shouldn't be in .tfvars
   instance_type = var.environment == "prod" ? "m5.large" : "t3.micro"
   
   # ✅ CORRECT - Logic in Terraform code, values in .tfvars
   # prod.tfvars
   instance_type = "m5.large"
   
   # dev.tfvars
   instance_type = "t3.micro"
   ```

#### Practical Code Examples

**Example: Multi-environment .tfvars implementation:**

```hcl
# variables.tf
variable "environment" {
  type        = string
  description = "Deployment environment"
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "instance_count" {
  type        = number
  description = "Number of application instances"
  
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 100
    error_message = "Instance count must be 1-100."
  }
}

variable "instance_type" {
  type        = string
  description = "EC2 instance type"
  
  validation {
    condition = can(regex("^[a-z][a-z0-9-]*\\.[a-z0-9]+$", var.instance_type))
    error_message = "Invalid instance type format."
  }
}

variable "database_config" {
  type = object({
    engine              = string
    version             = string
    allocated_storage   = number
    backup_retention    = number
    multi_az            = bool
  })
}

variable "tags" {
  type = map(string)
}

# main.tf
resource "aws_instance" "app" {
  count         = var.instance_count
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.instance_type
  
  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-app-${count.index + 1}"
    }
  )
}

resource "aws_db_instance" "main" {
  identifier           = "${var.environment}-database"
  engine               = var.database_config.engine
  engine_version       = var.database_config.version
  allocated_storage    = var.database_config.allocated_storage
  backup_retention_period = var.database_config.backup_retention
  multi_az             = var.database_config.multi_az
  
  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-database"
    }
  )
}
```

**Development environment (dev.tfvars):**

```hcl
environment = "development"
region      = "us-east-1"
instance_count = 1
instance_type  = "t3.micro"

database_config = {
  engine              = "postgres"
  version             = "14.7"
  allocated_storage   = 20
  backup_retention    = 7
  multi_az            = false
}

tags = {
  Environment = "development"
  CostCenter  = "engineering"
  Team        = "platform"
}
```

**Production environment (prod.tfvars):**

```hcl
environment = "production"
region      = "us-east-1"
instance_count = 5
instance_type  = "m5.large"

database_config = {
  engine              = "postgres"
  version             = "14.7"
  allocated_storage   = 500
  backup_retention    = 30
  multi_az            = true
}

tags = {
  Environment = "production"
  CostCenter  = "engineering"
  Team        = "platform"
  Compliance  = "sox-compliant"
}
```

**Deployment commands:**

```bash
# Development deployment
terraform init
terraform plan -var-file="environments/dev.tfvars"
terraform apply -var-file="environments/dev.tfvars"

# Production deployment with additional secrets
terraform plan \
  -var-file="environments/prod.tfvars" \
  -var "db_master_password=$DB_PASSWORD" \
  -out=prod.tfplan
terraform apply prod.tfplan
```

---

### 3.4 Outputs

#### Textual Deep Dive

**Architecture Role:**
Outputs expose infrastructure metadata to consumers—operators, other Terraform modules, CI/CD pipelines, and integrated systems. They form the **API contract** of a Terraform module, declaring what data is safe to consume and should remain stable across versions.

In layered infrastructure architecture:
- **Base infrastructure modules** output VPC IDs, subnet IDs, security group IDs
- **Application modules** consume those outputs and expose load balancer DNS names, database endpoints
- **Observability modules** consume application outputs to create monitoring dashboards
- **CI/CD systems** use outputs to configure deployment targets

**Internal Working Mechanism:**

Outputs are evaluated at the end of the apply phase and stored in state:

```
Resource Creation/Update
       │
       ▼
Output Expression Evaluation
├── Reference resolution (resource attributes available)
├── Type inference
├── Sensitive value detection
│
       ▼
State File Storage
├── Output values persisted
├── Sensitive flag noted (prevents display)
│
       ▼
Output Display
├── Normal outputs displayed in apply output
├── Sensitive outputs marked as redacted
│
       ▼
Remote State Availability
└── Accessible via terraform_remote_state data source
```

**Production Usage Patterns:**

1. **Module API contract:**
   ```hcl
   # networking module - outputs become consumed inputs for other modules
   output "vpc_id" {
     value       = aws_vpc.main.id
     description = "VPC identifier for child modules"
   }
   
   output "private_subnet_ids" {
     value       = aws_subnet.private[*].id
     description = "Private subnet IDs for application deployment"
   }
   
   output "nat_gateway_ips" {
     value       = aws_eip.nat[*].public_ip
     description = "Elastic IP addresses of NAT gateways (for allowlisting)"
   }
   ```

2. **Cross-module data consumption:**
   ```hcl
   # Parent module referencing child module outputs
   module "networking" {
     source = "./modules/networking"
   }
   
   module "compute" {
     source = "./modules/compute"
     
     vpc_id            = module.networking.vpc_id
     subnet_ids        = module.networking.private_subnet_ids
     security_group_id = module.networking.app_security_group_id
   }
   
   # Outputs from compute module
   output "application_endpoint" {
     value = module.compute.load_balancer_dns
   }
   ```

3. **Operational metadata for humans and systems:**
   ```hcl
   output "rds_endpoint" {
     value       = aws_db_instance.main.endpoint
     description = "RDS instance endpoint for application configuration"
   }
   
   output "bastion_ip" {
     value       = aws_instance.bastion.public_ip
     description = "Bastion host IP for emergency SSH access"
   }
   
   output "load_balancer_dns" {
     value       = aws_lb.main.dns_name
     description = "Application load balancer DNS name (add to Route53)"
   }
   ```

4. **CI/CD integration:**
   ```bash
   # Extract outputs for pipeline consumption
   APPLICATION_URL=$(terraform output -raw application_endpoint)
   RDS_ENDPOINT=$(terraform output -raw rds_endpoint)
   
   # Use in subsequent pipeline steps
   curl "https://${APPLICATION_URL}/health"
   psql -h "${RDS_ENDPOINT}" -c "SELECT version();"
   ```

**DevOps Best Practices:**

1. **Always provide descriptions:**
   ```hcl
   # ❌ WRONG - No context
   output "value1" {
     value = aws_instance.app.public_ip
   }
   
   # ✅ CORRECT - Clear description
   output "application_public_ip" {
     value       = aws_instance.app.public_ip
     description = "Public IP of load-balanced application servers"
   }
   ```

2. **Mark sensitive outputs to prevent exposure:**
   ```hcl
   # ❌ WRONG - Displays secrets in plan/apply
   output "db_password" {
     value = random_password.db.result
   }
   
   # ✅ CORRECT - Marked sensitive
   output "db_password" {
     value     = random_password.db.result
     sensitive = true
   }
   ```

3. **Use `-raw` for single string outputs in scripts:**
   ```bash
   # ❌ WRONG - Includes JSON formatting
   terraform output application_endpoint
   # Output: "app.example.com"
   
   # ✅ CORRECT - Pure string value
   terraform output -raw application_endpoint
   # Output: app.example.com
   
   # Usage in script
   ENDPOINT=$(terraform output -raw application_endpoint)
   ```

4. **Group related outputs for CLI readability:**
   ```hcl
   output "network_config" {
     value = {
       vpc_id              = aws_vpc.main.id
       private_subnet_ids  = aws_subnet.private[*].id
       nat_gateway_ips     = aws_eip.nat[*].public_ip
       nat_gateway_ids     = aws_nat_gateway.main[*].id
     }
     description = "Networking infrastructure identifiers"
   }
   
   output "security_config" {
     value = {
       app_security_group_id = aws_security_group.app.id
       db_security_group_id  = aws_security_group.db.id
     }
     description = "Security group identifiers"
   }
   ```

**Common Pitfalls:**

1. **Exposing sensitive data in outputs:**
   ```hcl
   # ❌ WRONG - Exposes database password
   output "database_connection_string" {
     value = "postgres://admin:${random_password.db.result}@${aws_db_instance.main.endpoint}:5432/mydb"
   }
   
   # ✅ CORRECT - Only expose safe connection details
   output "database_endpoint" {
     value = aws_db_instance.main.endpoint
   }
   ```

2. **Not using terraform_remote_state to consume outputs:**
   ```hcl
   # ❌ WRONG - Hardcoding values
   resource "aws_instance" "app" {
     subnet_id = "subnet-12345678"  # Magic value
   }
   
   # ✅ CORRECT - Reference another stack's outputs
   data "terraform_remote_state" "network" {
     backend = "s3"
     config = {
       bucket = "terraform-state"
       key    = "prod/networking/terraform.tfstate"
       region = "us-east-1"
     }
   }
   
   resource "aws_instance" "app" {
     subnet_id = data.terraform_remote_state.network.outputs.private_subnet_ids[0]
   }
   ```

3. **Outputs that change frequently breaking dependent systems:**
   ```hcl
   # ❌ WRONG - Using volatile resource attribute
   output "instance_id" {
     value = aws_instance.app[0].id  # Changes on replace
   }
   
   # ✅ CORRECT - Use stable identifiers
   output "instance_tag_name" {
     value = aws_instance.app[0].tags["Name"]  # Persists across replacements
   }
   ```

#### Practical Code Examples

**Example: Complete Terraform stack with comprehensive outputs:**

```hcl
# networking/outputs.tf
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC identifier"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Private subnet identifiers"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public subnet identifiers"
}

output "nat_gateway_ips" {
  value       = aws_eip.nat[*].public_ip
  description = "NAT gateway Elastic IP addresses"
}

output "app_security_group_id" {
  value       = aws_security_group.app.id
  description = "Application security group identifier"
}

# compute/outputs.tf
output "load_balancer_dns_name" {
  value       = aws_lb.main.dns_name
  description = "Load balancer DNS name for application access"
}

output "autoscaling_group_name" {
  value       = aws_autoscaling_group.app.name
  description = "Auto Scaling Group name for monitoring and debugging"
}

output "launch_template_id" {
  value       = aws_launch_template.app.id
  description = "EC2 Launch Template ID"
}

# database/outputs.tf
output "rds_endpoint" {
  value       = aws_db_instance.main.endpoint
  description = "RDS instance endpoint (hostname:port)"
}

output "database_name" {
  value       = aws_db_instance.main.db_name
  description = "Default database name"
}

output "database_username" {
  value       = aws_db_instance.main.username
  description = "RDS master username"
}

# root/main.tf - consuming all module outputs
module "networking" {
  source = "./modules/networking"
}

module "compute" {
  source = "./modules/compute"
  
  vpc_id            = module.networking.vpc_id
  subnet_ids        = module.networking.private_subnet_ids
  security_group_id = module.networking.app_security_group_id
}

module "database" {
  source = "./modules/database"
  
  vpc_id                   = module.networking.vpc_id
  security_group_id        = module.networking.app_security_group_id
}

# root/outputs.tf - expose final API contract
output "infrastructure_summary" {
  value = {
    application_endpoint = module.compute.load_balancer_dns_name
    database_endpoint    = module.database.rds_endpoint
    database_name        = module.database.database_name
    database_username    = module.database.database_username
  }
  description = "Complete infrastructure endpoints"
}

output "application_url" {
  value       = "https://${module.compute.load_balancer_dns_name}"
  description = "Application URL"
}

# Deployment and output extraction
# $ terraform apply
# $ terraform output -json infrastructure_summary > deploy_info.json
# $ cat deploy_info.json
# {
#   "application_endpoint": "app-lb-123.us-east-1.elb.amazonaws.com",
#   "database_endpoint": "prod-db.123456.us-east-1.rds.amazonaws.com:5432",
#   "database_name": "application_db",
#   "database_username": "dbadmin"
# }
```

---

---

## 4. Provisioning Patterns

### 4.1 Conditional Expressions

#### Textual Deep Dive

**Architecture Role:**
Conditional expressions (`condition ? true_value : false_value`) enable dynamic infrastructure behavior based on variables, local values, or data sources. They're foundational for:
- Environment-based configuration (different settings for dev vs. prod)
- Feature flags enabling/disabling infrastructure components
- Graceful fallback configurations
- Complex infrastructure evolution strategies

**Internal Working Mechanism:**

Conditional expressions are evaluated during the plan phase, before resource creation:

```
Variable/Local Evaluation
       │
       ▼
Conditional Expression Evaluation
├── Condition boolean evaluated
├── If true: true_value selected
├── If false: false_value selected
│
       ▼
Type Checking
├── Both branches must be compatible types
├── Result type is union of both branches
│
       ▼
Resource Application
└── Selected value used in resource configuration
```

**Type Compatibility Rules:**

```hcl
# ✅ CORRECT - Both branches same type
resource "aws_instance" "app" {
  instance_type = var.environment == "prod" ? "m5.large" : "t3.micro"
}

# ✅ CORRECT - Both branches compatible (implicit conversion)
resource "aws_instance" "app" {
  count = var.enable_app ? 1 : 0  # int types
}

# ❌ WRONG - Incompatible types
resource "aws_instance" "app" {
  instance_type = var.environment == "prod" ? "m5.large" : 123  # string vs number
}

# ✅ CORRECT - Complex types with all fields
resource "aws_db_instance" "main" {
  auto_minor_version_upgrade = var.environment == "prod" ? false : true
}
```

**Production Usage Patterns:**

1. **Environment-based sizing:**
   ```hcl
   locals {
     production_config = {
       instance_type       = "m5.xlarge"   # 4 vCPU, 16 GB RAM
       db_storage          = 500            # GB
       backup_retention    = 30             # days
       multi_az            = true
       monitoring_interval = 60             # seconds
     }
     
     development_config = {
       instance_type       = "t3.micro"     # 1 vCPU, 1 GB RAM
       db_storage          = 20             # GB
       backup_retention    = 7              # days
       multi_az            = false
       monitoring_interval = 300            # seconds
     }
   }
   
   resource "aws_instance" "app" {
     instance_type = var.environment == "prod" ? 
       local.production_config.instance_type : 
       local.development_config.instance_type
   }
   ```

2. **Feature flag enablement:**
   ```hcl
   # DR infrastructure only in production
   resource "aws_db_instance" "read_replica" {
     count                = var.enable_disaster_recovery ? 1 : 0
     identifier           = "${aws_db_instance.main.identifier}-replica"
     replicate_source_db  = aws_db_instance.main.identifier
   }
   
   # Monitoring dashboards only for prod and staging
   resource "cloudwatch_dashboard" "monitoring" {
     count          = contains(["prod", "staging"], var.environment) ? 1 : 0
     dashboard_name = "${var.application_name}-monitoring"
   }
   ```

3. **Graceful configuration fallback:**
   ```hcl
   # Use custom domain if provided, otherwise default to provider-generated DNS
   resource "route53_record" "app" {
     name    = var.custom_domain != null ? var.custom_domain : aws_lb.main.dns_name
     type    = var.custom_domain != null ? "CNAME" : "ALIAS"
     zone_id = var.custom_domain != null ? var.route53_zone_id : null
   }
   ```

**DevOps Best Practices:**

1. **Use ternary operators sparingly; prefer locals for complex logic:**
   ```hcl
   # ❌ WRONG - Nested ternaries are hard to read
   resource "aws_instance" "app" {
     instance_type = var.environment == "prod" ? 
       var.enable_gpu ? "g4dn.xlarge" : "m5.2xlarge" :
       var.environment == "staging" ?
       var.enable_gpu ? "g4dn.large" : "t3.xlarge" :
       "t3.micro"
   }
   
   # ✅ CORRECT - Use locals for complex logic
   locals {
     instance_types = {
       prod = {
         with_gpu    = "g4dn.xlarge"
         without_gpu = "m5.2xlarge"
       }
       staging = {
         with_gpu    = "g4dn.large"
         without_gpu = "t3.xlarge"
       }
       dev = {
         with_gpu    = "g4dn.large"
         without_gpu = "t3.micro"
       }
     }
     
     instance_type = local.instance_types[var.environment][var.enable_gpu ? "with_gpu" : "without_gpu"]
   }
   
   resource "aws_instance" "app" {
     instance_type = local.instance_type
   }
   ```

2. **Validate conditions with constraints:**
   ```hcl
   # ✅ CORRECT - Validates incompatible configurations
   variable "enable_disaster_recovery" {
     type = bool
   }
   
   variable "enable_autoscaling" {
     type = bool
   }
   
   # Validate that autoscaling is only enabled with DR
   variable "validation_rule" {
     type = bool
     default = (var.enable_autoscaling && !var.enable_disaster_recovery) ? (
       one(throw("Autoscaling requires disaster recovery to be enabled"))
     ) : true
   }
   ```

**Common Pitfalls:**

1. **Conditional count doesn't prevent resource creation in some backends:**
   ```hcl
   # ⚠️ CAUTION - Resource still created in state if count condition false
   resource "aws_db_instance" "standby" {
     count = var.enable_standby ? 1 : 0
     # Resources with count.index may error on subsequent apply if count changes
   }
   
   # ✅ PREFERRED - Use for_each with explicit keys for stability
   resource "aws_db_instance" "standby" {
     for_each = var.enable_standby ? { "standby" = true } : {}
     # State keys unlikely to shift unexpectedly
   }
   ```

2. **Forgetting both branches of ternary must be valid:**
   ```hcl
   # ❌ WRONG - False branch evaluated even if condition never reached
   resource "aws_instance" "app" {
     ami = var.use_custom_ami ? var.custom_ami_id : data.aws_ami.latest.id
     # If use_custom_ami is true, data.aws_ami.latest still evaluated and must exist
   }
   ```

#### Practical Code Examples

**Example: Multi-environment infrastructure with conditionals:**

```hcl
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "enable_disaster_recovery" {
  type    = bool
  default = false
  description = "Enable DR infrastructure (prod only recommended)"
}

variable "enable_detailed_monitoring" {
  type    = bool
  default = false
  description = "Enable CloudWatch detailed monitoring"
}

locals {
  # Environment-based configuration
  is_production = var.environment == "prod"
  is_staging    = var.environment == "staging"
  is_development = var.environment == "dev"
  
  # Sizing based on environment
  instance_type = {
    dev     = "t3.micro"
    staging = "t3.small"
    prod    = "m5.xlarge"
  }[var.environment]
  
  instance_count = {
    dev     = 1
    staging = 2
    prod    = 4
  }[var.environment]
  
  db_storage = {
    dev     = 20
    staging = 100
    prod    = 500
  }[var.environment]
  
  backup_retention = {
    dev     = 7
    staging = 14
    prod    = 30
  }[var.environment]
}

# Application instances
resource "aws_instance" "app" {
  count         = local.instance_count
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = local.instance_type
  
  # Production gets detailed monitoring at additional cost
  monitoring                = local.is_production || var.enable_detailed_monitoring
  associate_public_ip_address = !local.is_production  # Only in dev/staging
  
  tags = {
    Name = "${var.environment}-app-${count.index + 1}"
  }
}

# Primary database
resource "aws_db_instance" "main" {
  allocated_storage    = local.db_storage
  backup_retention_period = local.backup_retention
  
  # Multi-AZ for production only
  multi_az = local.is_production
  
  # Storage optimization
  storage_type          = local.is_production ? "io1" : "gp2"
  iops                  = local.is_production ? 3000 : null
  
  # Encryption for prod and staging
  storage_encrypted     = !local.is_development
  
  tags = {
    Name = "${var.environment}-database"
  }
}

# Disaster recovery: Read replica for production only
resource "aws_db_instance" "read_replica" {
  count                = local.is_production && var.enable_disaster_recovery ? 1 : 0
  identifier           = "${aws_db_instance.main.identifier}-replica"
  replicate_source_db  = aws_db_instance.main.identifier
  
  # Replica in different AZ
  availability_zone    = data.aws_availability_zones.available.names[1]
}

# Enhanced monitoring for production
resource "cloudwatch_log_group" "application" {
  count             = local.is_production ? 1 : 0
  name              = "/aws/ec2/${var.environment}-app"
  retention_in_days = 30
}

output "database_endpoint" {
  value = aws_db_instance.main.endpoint
}

output "has_disaster_recovery" {
  value = length(aws_db_instance.read_replica) > 0
}
```

---

### 4.2 count Meta-Argument

#### Textual Deep Dive

**Architecture Role:**
The `count` meta-argument enables provisioning multiple resources of the same type with identical configuration. It's the oldest Terraform pattern for handling resource multiplicity, using numeric indices (0, 1, 2...) to differentiate instances.

**Internal Working Mechanism:**

Count creates a list of resources indexed by position:

```
count = N
       │
       ▼
Resource[0], Resource[1], ..., Resource[N-1]
       │
       ▼
State Path: resource_type.resource_name[0], [1], [2]...
       │
       ▼
Removals or Index Shifts
└── Removing index 0 shifts all subsequent indices
    (state instability)
```

**State Addressing with count:**

```hcl
resource "aws_instance" "app" {
  count = 3
}

# State paths:
# aws_instance.app[0]
# aws_instance.app[1]
# aws_instance.app[2]

# If you change count to 2:
# Terraform removes aws_instance.app[2]
# aws_instance.app[0] and [1] remain (stable)

# If you remove item at index 1:
# Terraform removes aws_instance.app[1]
# aws_instance.app[2] becomes aws_instance.app[1] (UNSTABLE)
```

**Production Usage Patterns:**

1. **Simple scaling by count:**
   ```hcl
   variable "instance_count" {
     type    = number
     default = 3
   }
   
   resource "aws_instance" "app" {
     count         = var.instance_count
     instance_type = "t3.medium"
     
     # Each instance gets unique name via index
     tags = {
       Name = "app-server-${count.index}"
     }
   }
   ```

2. **Conditional resource creation:**
   ```hcl
   variable "enable_database" {
     type    = bool
     default = true
   }
   
   resource "aws_db_instance" "main" {
     count = var.enable_database ? 1 : 0
     # Resource either exists (count.index = 0) or doesn't exist
     
     # Access the single resource:
     # aws_db_instance.main[0]
   }
   ```

3. **Availability zone distribution:**
   ```hcl
   data "aws_availability_zones" "available" {
     state = "available"
   }
   
   resource "aws_instance" "app" {
     count             = 3
     availability_zone = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
     
     # Distributes across AZs: 0→us-east-1a, 1→us-east-1b, 2→us-east-1c
   }
   ```

**DevOps Best Practices:**

1. **Use count for uniform collections, not maps:**
   ```hcl
   # ✅ CORRECT - Numeric indices for homogeneous resources
   resource "aws_instance" "app" {
     count = 5  # 5 identical application servers
   }
   
   # ⚠️ PROBLEMATIC - Count used for semantic keys
   variable "instance_names" {
     type = list(string)
     default = ["web", "api", "worker"]
   }
   
   resource "aws_instance" "services" {
     count = length(var.instance_names)
     tags = { Name = var.instance_names[count.index] }
   }
   # Problem: Removing middle item shifts state indices
   ```

2. **Combine count with lookup for list iteration:**
   ```hcl
   # ✅ CORRECT - Using count with indexed access
   variable "subnet_cidrs" {
     type = list(string)
     default = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
   }
   
   resource "aws_subnet" "main" {
     count             = length(var.subnet_cidrs)
     vpc_id            = aws_vpc.main.id
     cidr_block        = var.subnet_cidrs[count.index]
     availability_zone = data.aws_availability_zones.available.names[count.index]
   }
   
   # Reference all subnets: aws_subnet.main[*].id
   # Reference specific:   aws_subnet.main[0].id
   ```

3. **Be cautious about removing items from count-based lists:**
   ```hcl
   # ❌ RISKY - Removing middle element shifts indices
   variable "instance_names" {
     type    = list(string)
     default = ["web-1", "web-2", "web-3", "web-4"]  # Removing web-2 shifts indices
   }
   
   # ✅ SAFER - Use count for stable iteration
   resource "aws_instance" "app" {
     for_each = toset(var.instance_names)  # Use for_each instead
   }
   ```

**Common Pitfalls:**

1. **Count index instability when removing items:**
   ```hcl
   # Original configuration:
   variable "server_list" {
     default = ["server-a", "server-b", "server-c"]
   }
   
   resource "aws_instance" "servers" {
     count = length(var.server_list)
     tags = { Name = var.server_list[count.index] }
   }
   
   # State created:
   # aws_instance.servers[0]  → server-a
   # aws_instance.servers[1]  → server-b
   # aws_instance.servers[2]  → server-c
   
   # Later, you remove "server-b":
   variable "server_list" {
     default = ["server-a", "server-c"]  # Removed middle item
   }
   
   # Terraform will destroy aws_instance.servers[2] (server-c)
   # and aws_instance.servers[1] (server-b)
   # Then create new index 1 with server-c data
   # ❌ Unnecessary destruction/recreation!
   ```

2. **Forgetting to handle empty count:**
   ```hcl
   resource "aws_instance" "optional" {
     count = var.enable ? 1 : 0
   }
   
   # ❌ WRONG - Assumes resource always exists
   resource "aws_security_group_rule" "app" {
     security_group_id = aws_instance.optional.id
   }
   
   # ✅ CORRECT - Use conditional reference
   resource "aws_security_group_rule" "app" {
     count             = var.enable ? 1 : 0
     security_group_id = aws_instance.optional[0].id
   }
   
   # Or use dynamic block
   resource "aws_security_group_rule" "app" {
     for_each = aws_instance.optional
     security_group_id = each.value.id
   }
   ```

#### Practical Code Examples

**Example: Multi-tier application with count-based scaling:**

```hcl
variable "instance_count" {
  type    = number
  default = 3
  description = "Number of application instances"
  
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 10
    error_message = "Instance count must be 1-10."
  }
}

variable "environment" {
  type = string
}

data "aws_availability_zones" "available" {
  state = "available"
}

# Create N instances distributed across AZs
resource "aws_instance" "app" {
  count                = var.instance_count
  ami                  = data.aws_ami.amazon_linux_2.id
  instance_type        = "t3.medium"
  subnet_id            = aws_subnet.private[count.index % length(aws_subnet.private)].id
  availability_zone    = data.aws_availability_zones.available.names[count.index % length(data.aws_availability_zones.available.names)]
  
  iam_instance_profile = aws_iam_instance_profile.app.name
  security_groups      = [aws_security_group.app.id]
  
  tags = {
    Name  = "${var.environment}-app-${count.index + 1}"
    Index = count.index
  }
}

# Register all instances with load balancer
resource "aws_lb_target_group_attachment" "app" {
  count            = var.instance_count
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app[count.index].id
  port             = 8080
}

# Outputs
output "instance_ids" {
  value       = aws_instance.app[*].id
  description = "All application instance IDs"
}

output "instance_ips" {
  value       = aws_instance.app[*].private_ip
  description = "All application instance private IPs"
}

output "instance_count" {
  value = var.instance_count
}

# Deployment
# $ terraform apply -var="instance_count=3"
# $ terraform apply -var="instance_count=5"  # Scales from 3 to 5
```

---

### 4.3 for_each Meta-Argument

#### Textual Deep Dive

**Architecture Role:**
`for_each` is the modern, preferred approach for creating multiple resource instances. Unlike `count`, it uses string keys (from maps or sets) to identify resources, providing stability when collections change. It's essential for:
- Creating resources from map/object data
- Maintaining stable state across configuration changes
- Complex multi-instance scenarios with semantic meaning

**Internal Working Mechanism:**

For_each creates a map-like structure indexed by string keys:

```
for_each = {
  "app-1" = {...}
  "app-2" = {...}
}
       │
       ▼
Resource["app-1"], Resource["app-2"]
       │
       ▼
State Path: resource_type.resource_name["app-1"], ["app-2"]...
       │
       ▼
Key-based Addressing (Stable)
└── Removing "app-1" leaves "app-2" unchanged
    (state stable even with removals)
```

**Type Compatibility:**

```hcl
# Set of strings
for_each = toset(["web", "api", "worker"])

# Map with string keys
for_each = {
  web    = { instance_type = "t3.small" }
  api    = { instance_type = "m5.medium" }
  worker = { instance_type = "t3.medium" }
}

# Can convert lists to maps
for_each = { for name in var.server_names : name => {} }

# Cannot use numeric indices or lists directly
# for_each = [1, 2, 3]  # ❌ INVALID
# Use for loops or count for lists
```

**Production Usage Patterns:**

1. **Environment-based infrastructure:**
   ```hcl
   variable "environments" {
     type = map(object({
       instance_type = string
       instance_count = number
     }))
     
     default = {
       dev = {
         instance_type  = "t3.micro"
         instance_count = 1
       }
       staging = {
         instance_type  = "t3.small"
         instance_count = 2
       }
       prod = {
         instance_type  = "m5.large"
         instance_count = 4
       }
     }
   }
   
   resource "aws_instance" "app" {
     for_each      = var.environments
     instance_type = each.value.instance_type
     count         = each.value.instance_count  # ⚠️ Limited nesting
     
     tags = { Environment = each.key }
   }
   ```

2. **Multi-region deployments:**
   ```hcl
   variable "regions" {
     type = map(object({
       aws_region = string
       cidr_block = string
     }))
     
     default = {
       primary = {
         aws_region = "us-east-1"
         cidr_block = "10.0.0.0/16"
       }
       secondary = {
         aws_region = "us-west-2"
         cidr_block = "10.1.0.0/16"
       }
     }
   }
   
   provider "aws" {
     alias  = each.key
     region = each.value.aws_region
   }
   
   resource "aws_vpc" "main" {
     for_each = var.regions
     
     provider   = aws.${each.key}  # Use region-specific provider
     cidr_block = each.value.cidr_block
     
     tags = { Name = "${each.key}-vpc" }
   }
   ```

3. **Application tiers with semantic keys:**
   ```hcl
   variable "tiers" {
     type = set(string)
     default = ["web", "api", "worker", "cache"]
   }
   
   locals {
     tier_config = {
       web = {
         instance_type = "t3.small"
         port          = 80
       }
       api = {
         instance_type = "t3.medium"
         port          = 8080
       }
       worker = {
         instance_type = "t3.medium"
         port          = null
       }
       cache = {
         instance_type = "t3.micro"
         port          = 6379
       }
     }
   }
   
   resource "aws_security_group" "tier" {
     for_each = var.tiers
     name     = "${var.environment}-${each.key}-sg"
   }
   
   resource "aws_instance" "tier" {
     for_each      = var.tiers
     instance_type = local.tier_config[each.key].instance_type
     security_groups = [aws_security_group.tier[each.key].id]
     
     tags = { Tier = each.key }
   }
   ```

**DevOps Best Practices:**

1. **Use for_each over count for dict-like collections:**
   ```hcl
   # ✅ CORRECT - Semantic keys with for_each
   variable "instance_config" {
     type = map(string)
     default = {
       database   = "t3.large"
       cache      = "t3.micro"
       application = "t3.medium"
     }
   }
   
   resource "aws_instance" "app" {
     for_each      = var.instance_config
     instance_type = each.value
     tags = { Role = each.key }
   }
   ```

2. **Safe iteration with list-to-map conversion:**
   ```hcl
   variable "instance_names" {
     type = list(string)
   }
   
   # Convert list to map for stable for_each
   resource "aws_instance" "app" {
     for_each = { for name in var.instance_names : name => {} }
     
     tags = { Name = each.key }
   }
   ```

3. **Group-based resource configuration:**
   ```hcl
   variable "resource_groups" {
     type = map(map(string))
     
     default = {
       production = {
         subnet_id         = "subnet-12345"
         security_group_id = "sg-67890"
       }
       staging = {
         subnet_id         = "subnet-54321"
         security_group_id = "sg-09876"
       }
     }
   }
   
   resource "aws_instance" "grouped" {
     for_each       = var.resource_groups
     subnet_id      = each.value.subnet_id
     security_groups = [each.value.security_group_id]
     
     tags = { Environment = each.key }
   }
   ```

**Common Pitfalls:**

1. **Using count when for_each is safer:**
   ```hcl
   # ❌ PROBLEMATIC - List iteration with count
   variable "environment_list" {
     type    = list(string)
     default = ["dev", "staging", "prod"]
   }
   
   resource "aws_vpc" "main" {
     count = length(var.environment_list)
     tags = { Name = var.environment_list[count.index] }
   }
   # Removing middle item (staging) shifts prod to index 1
   
   # ✅ CORRECT - Use for_each for semantic stability
   resource "aws_vpc" "main" {
     for_each = toset(var.environment_list)
     tags = { Name = each.key }
   }
   ```

2. **Forgetting each.key and each.value context:**
   ```hcl
   variable "instances" {
     type = map(object({
       instance_type = string
       count         = number
     }))
   }
   
   resource "aws_instance" "app" {
     for_each = var.instances
     
     # ✅ CORRECT - Using each context
     instance_type = each.value.instance_type
     tags = { Name = each.key }
     
     # ❌ WRONG - each not available
     # instance_type = var.instances[key].instance_type
   }
   ```

#### Practical Code Examples

**Example: Multi-environment, multi-tier infrastructure with for_each:**

```hcl
variable "environments" {
  type = map(object({
    vpc_cidr = string
    instance_type = string
    instance_count = number
  }))
  
  default = {
    development = {
      vpc_cidr       = "10.0.0.0/16"
      instance_type  = "t3.micro"
      instance_count = 1
    }
    staging = {
      vpc_cidr       = "10.1.0.0/16"
      instance_type  = "t3.small"
      instance_count = 2
    }
    production = {
      vpc_cidr       = "10.2.0.0/16"
      instance_type  = "m5.large"
      instance_count = 3
    }
  }
}

# Create VPC for each environment
resource "aws_vpc" "main" {
  for_each   = var.environments
  cidr_block = each.value.vpc_cidr
  
  tags = {
    Name        = "${each.key}-vpc"
    Environment = each.key
  }
}

# Create internet gateway for each VPC
resource "aws_internet_gateway" "main" {
  for_each = aws_vpc.main
  vpc_id   = each.value.id
  
  tags = { Name = "${each.key}-igw" }
}

# Create subnets: 2 per environment
resource "aws_subnet" "main" {
  for_each = {
    for env_name, env_config in var.environments :
    # Create composite key for each subnet
    "${env_name}-1" => {
      vpc_id            = aws_vpc.main[env_name].id
      cidr_block        = "${cidrsubnets(env_config.vpc_cidr, 2)[0]}"
      availability_zone = "${data.aws_availability_zones.available.names[0]}"
    }
    "${env_name}-2" => {
      vpc_id            = aws_vpc.main[env_name].id
      cidr_block        = "${cidrsubnets(env_config.vpc_cidr, 2)[1]}"
      availability_zone = "${data.aws_availability_zones.available.names[1]}"
    }
  }
  
  vpc_id            = each.value.vpc_id
  cidr_block        = each.value.cidr_block
  availability_zone = each.value.availability_zone
  
  tags = { Name = "subnet-${each.key}" }
}

# Create application instances
resource "aws_instance" "app" {
  for_each = {
    for env_name, env_config in var.environments :
    env_name => {
      instance_type  = env_config.instance_type
      instance_count = env_config.instance_count
      subnet_ids     = [for subnet in aws_subnet.main : subnet.id if can(regex("^${env_name}", subnet.tags.Name))]
    }
  }
  
  # Cannot nest for_each + count; workaround with index
  # This example shows the pattern for single instance
  instance_type  = each.value.instance_type
  subnet_id      = each.value.subnet_ids[0]
  ami            = data.aws_ami.amazon_linux_2.id
  
  tags = {
    Name        = "${each.key}-app"
    Environment = each.key
  }
}

# Outputs
output "vpc_ids" {
  value = { for env, vpc in aws_vpc.main : env => vpc.id }
}

output "subnet_ids" {
  value = { for subnet_name, subnet in aws_subnet.main : subnet_name => subnet.id }
}
```

---

### 4.4 Dynamic Blocks

#### Textual Deep Dive

**Architecture Role:**
Dynamic blocks enable conditional, iterative generation of nested resource blocks. They're essential for avoiding repetitive block declarations when configuration comes from variables or computed values. Common use cases:
- Variable number of security group rules
- Dynamic IAM policy statements
- Multiple network interfaces with varying configurations
- Conditional logging, monitoring, or encryption settings

**Internal Working Mechanism:**

Dynamic blocks are expanded during planning, before resource creation:

```
for_each expression evaluation
       │
       ▼
Iteration over collection
├── Each iteration: context available as dynamic.VALUE.key/value
├── Block content evaluated for each iteration
│
       ▼
Nested Block Generation
├── Multiple copies of nested block created
├── Each copy contains iteration-specific values
│
       ▼
Resource Application
└── Resource created with all generated nested blocks
```

**Syntax Structure:**

```hcl
resource "aws_security_group" "example" {
  name = "example"
  
  # Dynamic block declaration
  dynamic "ingress" {              # Block type (ingress, egress, rule, etc.)
    for_each = var.ingress_rules   # Iteration source
    content {                       # Block content template
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }
}
```

**Variable Context:**

Within a dynamic block, `dynamic_block_name.key` provides:
- `dynamic.VALUE.key` - The key (if iterating map)
- `dynamic.VALUE.value` - The value

**Production Usage Patterns:**

1. **Dynamic security group rules:**
   ```hcl
   variable "ingress_rules" {
     type = list(object({
       from_port   = number
       to_port     = number
       protocol    = string
       cidr_blocks = list(string)
     }))
     
     default = [
       {
         from_port   = 80
         to_port     = 80
         protocol    = "tcp"
         cidr_blocks = ["0.0.0.0/0"]
       },
       {
         from_port   = 443
         to_port     = 443
         protocol    = "tcp"
         cidr_blocks = ["0.0.0.0/0"]
       },
       {
         from_port   = 22
         to_port     = 22
         protocol    = "tcp"
         cidr_blocks = ["10.0.0.0/8"]
       }
     ]
   }
   
   resource "aws_security_group" "web" {
     name = "web-sg"
     
     dynamic "ingress" {
       for_each = var.ingress_rules
       content {
         from_port   = ingress.value.from_port
         to_port     = ingress.value.to_port
         protocol    = ingress.value.protocol
         cidr_blocks = ingress.value.cidr_blocks
       }
     }
   }
   ```

2. **Dynamic IAM policy statements:**
   ```hcl
   variable "iam_permissions" {
     type = list(object({
       effect    = string
       actions   = list(string)
       resources = list(string)
     }))
   }
   
   resource "aws_iam_role_policy" "app" {
     name = "app-policy"
     role = aws_iam_role.app.id
     
     policy = jsonencode({
       Version = "2012-10-17"
       Statement = [
         for perm in var.iam_permissions : {
           Effect   = perm.effect
           Action   = perm.actions
           Resource = perm.resources
         }
       ]
     })
   }
   
   # Or using dynamic blocks:
   data "aws_iam_policy_document" "app" {
     dynamic "statement" {
       for_each = var.iam_permissions
       content {
         effect    = statement.value.effect
         actions   = statement.value.actions
         resources = statement.value.resources
       }
     }
   }
   ```

3. **Dynamic volume attachments:**
   ```hcl
   variable "additional_volumes" {
     type = map(object({
       size = number
       type = string
     }))
     
     default = {
       data = {
         size = 100
         type = "gp2"
       }
       logs = {
         size = 50
         type = "gp2"
       }
     }
   }
   
   resource "aws_instance" "app" {
     ami           = data.aws_ami.amazon_linux_2.id
     instance_type = "t3.medium"
     
     root_block_device {
       volume_size = 20
       volume_type = "gp2"
     }
     
     # Dynamic additional volumes
     dynamic "ebs_block_device" {
       for_each = var.additional_volumes
       content {
         device_name = "/dev/sd${chr(98 + index(keys(var.additional_volumes), ebs_block_device.key))}"
         volume_size = ebs_block_device.value.size
         volume_type = ebs_block_device.value.type
       }
     }
   }
   ```

**DevOps Best Practices:**

1. **Use dynamic blocks only when necessary:**
   ```hcl
   # ✅ CORRECT - Dynamic when count varies
   variable "rules" {
     type = list(string)
   }
   
   resource "aws_security_group" "app" {
     dynamic "ingress" {
       for_each = var.rules
       content {
         # Rule configuration
       }
     }
   }
   
   # ✅ ALSO CORRECT - Static when fixed structure
   resource "aws_security_group" "web" {
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
   }
   ```

2. **Avoid deeply nested dynamic blocks:**
   ```hcl
   # ❌ WRONG - Nested dynamicblocks are hard to understand
   dynamic "outer" {
     for_each = var.outer_list
     content {
       dynamic "inner" {
         for_each = outer.value.inner_list
         content {
           # Complex logic here
         }
       }
     }
   }
   
   # ✅ CORRECT - Flatten or precompute in locals
   locals {
     flattened = flatten([
       for outer_item in var.outer_list : [
         for inner_item in outer_item.inner_list : {
           outer_val = outer_item
           inner_val = inner_item
         }
       ]
     ])
   }
   
   dynamic "rule" {
     for_each = local.flattened
     content {
       # Cleaner logic
     }
   }
   ```

**Common Pitfalls:**

1. **Forgetting for_each necessity:**
   ```hcl
   # ❌ WRONG - Dynamic block without iteration
   resource "aws_security_group" "app" {
     dynamic "ingress" {
       for_each = [aws_vpc.main]  # Unnecessary iteration
       content {
         # Single rule
       }
     }
   }
   
   # ✅ CORRECT - Static block for fixed configuration
   resource "aws_security_group" "app" {
     ingress {
       # Single rule
     }
   }
   ```

2. **Using undefined variables in dynamic blocks:**
   ```hcl
   variable "enable_rules" {
     type = bool
     default = false
   }
   
   variable "rules" {
     type = list(string)
     default = []
   }
   
   # ❌ WRONG - Dynamic block may fail if variable undefined
   resource "aws_security_group" "app" {
     dynamic "ingress" {
       for_each = var.rules
       content {
         # Fails if var.rules is null or undefined
       }
     }
   }
   
   # ✅ CORRECT - Validate or provide defaults
   resource "aws_security_group" "app" {
     dynamic "ingress" {
       for_each = coalesce(var.rules, [])
       content {
         # Safe even if var.rules is null
       }
     }
   }
   ```

#### Practical Code Examples

**Example: Complete dynamic security group configuration:**

```hcl
variable "security_group_rules" {
  type = object({
    ingress = list(object({
      from_port       = number
      to_port         = number
      protocol        = string
      security_groups = list(string)
      cidr_blocks     = list(string)
    }))
    egress = list(object({
      from_port       = number
      to_port         = number
      protocol        = string
      cidr_blocks     = list(string)
    }))
  })
  
  default = {
    ingress = [
      {
        from_port       = 80
        to_port         = 80
        protocol        = "tcp"
        security_groups = []
        cidr_blocks     = ["0.0.0.0/0"]
      },
      {
        from_port       = 443
        to_port         = 443
        protocol        = "tcp"
        security_groups = []
        cidr_blocks     = ["0.0.0.0/0"]
      },
      {
        from_port       = 22
        to_port         = 22
        protocol        = "tcp"
        security_groups = []
        cidr_blocks     = ["10.0.0.0/8"]
      }
    ]
    egress = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
      }
    ]
  }
}

resource "aws_security_group" "main" {
  name        = "dynamic-sg"
  description = "Security group with dynamic rules"
  vpc_id      = aws_vpc.main.id
  
  # Dynamic ingress rules
  dynamic "ingress" {
    for_each = var.security_group_rules.ingress
    content {
      from_port       = ingress.value.from_port
      to_port         = ingress.value.to_port
      protocol        = ingress.value.protocol
      security_groups = ingress.value.security_groups
      cidr_blocks     = ingress.value.cidr_blocks
    }
  }
  
  # Dynamic egress rules
  dynamic "egress" {
    for_each = var.security_group_rules.egress
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }
  
  tags = { Name = "main-sg" }
}

# Deploy with custom rules
# terraform apply -var='security_group_rules={ingress=[...],egress=[...]}'
```

---

---

## 5. Lifecycle Management

### 5.1 Lifecycle Rules Overview

#### Textual Deep Dive

**Architecture Role:**
Lifecycle meta-arguments control Terraform's behavior when modifying or destroying resources. They're essential for:
- Preventing accidental deletion of critical infrastructure
- Implementing zero-downtime deployments
- Managing stateful resources and changing immutable attributes
- Graceful infrastructure evolution

**Internal Working Mechanism:**

Lifecycle rules intercept resource actions during apply:

```
Terraform Plan Analysis
       │
       ▼
Changes Detected (create/update/delete)
       │
       ├─► Check lifecycle.prevent_destroy → Block delete if set
       │
       ├─► Check lifecycle.create_before_destroy → Create new before delete old
       │
       ├─► Check lifecycle.ignore_changes → Skip detected changes
       │
       └─► Check lifecycle.replace_triggered_by → Force replacement based on triggers
                │
                ▼
           Apply Phase
           └─► Execute with lifecycle constraints enforced
```

**Global Lifecycle Properties:**

```hcl
lifecycle {
  create_before_destroy = bool   # Create new before destroying old
  prevent_destroy       = bool   # Prevent destruction entirely
  ignore_changes        = [...]  # Ignore specific attribute changes
  replace_triggered_by  = [...]  # Force replacement on changes
  ignore_lifecycle      = bool   # Ignore all lifecycle rules (rare)
}
```

### 5.2 prevent_destroy

#### Textual Deep Dive

**Architecture Role:**
`prevent_destroy` blocks resource destruction, protecting critical infrastructure from accidental deletion via `terraform destroy` or manual removal from configuration.

**Internal Working Mechanism:**

```
Delete Operation Triggered
       │
       ▼
Check prevent_destroy = true
       │
       ├─ YES: Return error, block delete
       │
       └─ NO: Proceed with destruction
```

**Production Usage Patterns:**

1. **Protecting critical databases:**
   ```hcl
   resource "aws_db_instance" "production" {
     identifier = "prod-database"
     # ... configuration ...
     
     lifecycle {
       prevent_destroy = true
     }
   }
   
   # Attempting terraform destroy will fail:
   # Error: Resource instance protected by lifecycle.prevent_destroy
   ```

2. **Protecting shared resources:**
   ```hcl
   resource "aws_vpc" "shared_infrastructure" {
     cidr_block = "10.0.0.0/16"
     
     lifecycle {
       prevent_destroy = true
     }
   }
   
   # Must manually remove lifecycle block before destruction
   ```

3. **Conditional protection:**
   ```hcl
   variable "environment" {
     type = string
   }
   
   resource "aws_db_instance" "main" {
     # ... configuration ...
     
     lifecycle {
       # Only protect production database
       prevent_destroy = var.environment == "prod"
     }
   }
   ```

**DevOps Best Practices:**

1. **Use for production-critical resources only:**
   ```hcl
   # ✅ CORRECT - Protect critical data stores
   resource "aws_rds" "main" {
     # ...
     lifecycle {
       prevent_destroy = true
     }
   }
   
   # ✅ CORRECT - Protect shared infrastructure
   resource "aws_vpc" "main" {
     # ...
     lifecycle {
       prevent_destroy = true
     }
   }
   ```

2. **Document why prevent_destroy is needed:**
   ```hcl
   resource "aws_db_instance" "main" {
     identifier = "prod-database"
     # Database contains production customer data
     # Deletion requires manual intervention and approval
     
     lifecycle {
       prevent_destroy = true
     }
   }
   ```

**Common Pitfalls:**

1. **prevent_destroy blocks state removal:**
   ```hcl
   # ⚠️ LIMITATION - prevent_destroy doesn't block state removal
   # This still works but leaves AWS resource dangling:
   terraform state rm aws_db_instance.main
   
   # The database still exists in AWS but is unmanaged
   ```

2. **prevent_destroy blocks all destructive operations:**
   ```hcl
   # ❌ PROBLEM - Cannot modify immutable attributes
   resource "aws_db_instance" "main" {
     engine = "postgres"
     # ... other config ...
     
     lifecycle {
       prevent_destroy = true
     }
   }
   
   # If engine is immutable and needs change:
   # Either provide new attribute without lifecycle constraint
   # Or create new resource with create_before_destroy
   ```

#### Practical Code Examples

```hcl
# Example: Multi-tier infrastructure with selective protection

variable "environment" {
  type = string
}

# ✅ Critical production database protected
resource "aws_db_instance" "main" {
  identifier           = "${var.environment}-database"
  allocated_storage    = var.environment == "prod" ? 500 : 50
  engine               = "postgres"
  engine_version       = "14.7"
  
  lifecycle {
    prevent_destroy = var.environment == "prod"
  }
}

# ✅ S3 bucket with state data protected
resource "aws_s3_bucket" "application_data" {
  bucket = "${var.environment}-app-data"
  
  lifecycle {
    prevent_destroy = var.environment == "prod"
  }
}

# ❌ Ephemeral instances not protected
resource "aws_instance" "worker" {
  instance_type = "t3.micro"
  # No prevent_destroy - can be replaced freely
}

output "protected_resources" {
  value = var.environment == "prod" ? ["database", "s3_bucket"] : []
}
```

---

### 5.3 create_before_destroy

#### Textual Deep Dive

**Architecture Role:**
`create_before_destroy` implements zero-downtime updates by provisioning replacement infrastructure before removing the original. Essential for:
- Stateless application servers
- Load-balanced infrastructure
- Blue-green deployments
- Minimizing service interruption

**Internal Working Mechanism:**

```
Normal Update Sequence:
Destroy Old → Create New → Downtime window exists

create_before_destroy Sequence:
Create New → (Both active temporarily) → Destroy Old → Zero downtime
```

**Dependency Handling:**

Create_before_destroy changes reference behavior:

```hcl
resource "aws_instance" "app" {
  instance_type = "t3.medium"
  
  lifecycle {
    create_before_destroy = true
  }
}

# With create_before_destroy = true:
# - New instance created first
# - Load balancer gradually shifts traffic
# - Old instance destroyed when safe

# With create_before_destroy = false (default):
# - Old instance destroyed immediately
# - New instance created after
# - Traffic interruption during replacement
```

**Production Usage Patterns:**

1. **Stateless web server updates:**
   ```hcl
   locals {
     instance_types = {
       v1 = "t3.small"
       v2 = "t3.medium"  # Upgrade after deployment
     }
   }
   
   resource "aws_instance" "web" {
     instance_type = local.instance_types[var.deployment_version]
     
     lifecycle {
       create_before_destroy = true
     }
   }
   
   # When deployment_version changes: t3.small → t3.medium
   # New t3.medium created, then old t3.small destroyed
   ```

2. **Auto Scaling Group updates:**
   ```hcl
   resource "aws_launch_template" "app" {
     image_id      = var.ami_id
     instance_type = var.instance_type
   }
   
   resource "aws_autoscaling_group" "app" {
     max_size         = 10
     min_size         = 3
     health_check_type = "ELB"
     
     launch_template {
       id      = aws_launch_template.app.id
       version = aws_launch_template.app.latest_version_number
     }
     
     lifecycle {
       create_before_destroy = true
     }
   }
   ```

3. **Container orchestration with rolling updates:**
   ```hcl
   resource "aws_ecs_service" "app" {
     name            = "app-service"
     cluster         = aws_ecs_cluster.main.id
     task_definition = aws_ecs_task_definition.app.arn
     desired_count   = 3
     
     deployment_configuration {
       maximum_percent         = 200  # Allow 200% capacity during update
       minimum_healthy_percent = 100
     }
     
     lifecycle {
       create_before_destroy = true
     }
   }
   ```

**DevOps Best Practices:**

1. **Use only for stateless resources:**
   ```hcl
   # ✅ CORRECT - Stateless application servers
   resource "aws_instance" "app" {
     lifecycle {
       create_before_destroy = true
     }
   }
   
   # ❌ WRONG - Stateful database
   resource "aws_db_instance" "main" {
     lifecycle {
       create_before_destroy = true  # Will create new DB instance
     }  # Data and connections preserved, but complicated
   }
   ```

2. **Coordinate with load balancing:**
   ```hcl
   resource "aws_instance" "app" {
     # ... configuration ...
     
     lifecycle {
       create_before_destroy = true
     }
   }
   
   # Register with load balancer
   resource "aws_lb_target_group_attachment" "app" {
     target_group_arn = aws_lb_target_group.app.arn
     target_id        = aws_instance.app.id
     
     # Load balancer auto-detects new instance
     lifecycle {
       create_before_destroy = true
     }
   }
   ```

**Common Pitfalls:**

1. **create_before_destroy requires extra capacity:**
   ```hcl
   # ⚠️ WARNING - Temporarily doubles resource count
   resource "aws_instance" "app" {
     count = 5
     
     lifecycle {
       create_before_destroy = true
     }
   }
   
   # During update: 5 old instances + 5 new instances = 10 total
   # Budget for 2x resource usage during updates
   ```

2. **create_before_destroy on single-instance resources:**
   ```hcl
   # ❌ PROBLEM - Creates duplicate before destroying
   resource "aws_db_instance" "main" {
     identifier = "prod-db"
     
     lifecycle {
       create_before_destroy = true
     }
   }
   
   # Terraform will fail because:
   # 1. Try to create new instance with same identifier
   # 2. Database identifier must be unique
   # 3. Cannot have 2 instances with same ID
   ```

#### Practical Code Examples

```hcl
# Example: Zero-downtime application update

variable "instance_type" {
  type    = string
  default = "t3.small"
}

variable "ami_id" {
  type = string
}

# Create N instances scheduled for rolling update
resource "aws_instance" "app" {
  count         = 3
  ami           = var.ami_id
  instance_type = var.instance_type
  
  # Register with load balancer
  security_groups = [aws_security_group.app.id]
  
  # Zero-downtime update strategy
  lifecycle {
    create_before_destroy = true
  }
  
  tags = {
    Name = "app-${count.index + 1}"
    Role = "web-server"
  }
}

# Register all instances with load balancer
resource "aws_lb_target_group_attachment" "app" {
  count            = 3
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app[count.index].id
  port             = 80
}

# Health check ensures no traffic during replacement
resource "aws_lb_target_group" "app" {
  name     = "app-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id
  
  health_check {
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 3
    interval            = 30
    path                = "/health"
  }
}

output "application_url" {
  value = aws_lb.main.dns_name
}

# Deployment:
# $ terraform apply -var="instance_type=t3.medium"
# 
# Terraform will:
# 1. Create 3 new t3.medium instances
# 2. Wait for health checks to pass
# 3. Destroy 3 old t3.small instances
# 4. Throughout: Load balancer routes all traffic to healthy instances
```

---

### 5.4 ignore_changes

#### Textual Deep Dive

**Architecture Role:**
`ignore_changes` tells Terraform to ignore detected changes to specific attributes, useful for:
- Attributes changed by external systems (auto-scaling, cloud provider)
- One-time configuration (SSH keys, initialization)
- High-churn attributes (timestamps, revision numbers)
- Reducing plan noise

**Internal Working Mechanism:**

```
Terraform State Comparison
       │
       ▼
Detect Attribute Changes
       │
       ├─ Attribute in ignore_changes list? → Skip reporting
       │
       └─ Attribute not ignored → Report change
                │
                ▼
           Plan Output
           └─ Only non-ignored changes shown
```

**Scope:**

```hcl
lifecycle {
  # Ignore all changes to specific attributes
  ignore_changes = [parameter_group_name]
  
  # Ignore changes to deeply nested attributes
  ignore_changes = [
    tags["ManagedBy"],  # Specific tag
    settings[0].value   # Specific array element
  ]
  
  # Ignore all changes (nuclear option, use rarely)
  ignore_changes = all
}
```

**Production Usage Patterns:**

1. **Ignore cloud provider modifications:**
   ```hcl
   # RDS automatically updates minor versions during maintenance window
   resource "aws_db_instance" "main" {
     allocated_storage = 100
     # ...
     
     lifecycle {
       # Ignore auto_minor_version_upgrade changes made by AWS
       ignore_changes = [
         engine_version,  # AWS patches automatically
       ]
     }
   }
   ```

2. **Ignore externally managed tags:**
   ```hcl
   resource "aws_instance" "app" {
     # ... instance configuration ...
     
     tags = {
       Environment = "production"
       Team        = "platform"
     }
     
     lifecycle {
       # Ignore tags added by external systems (cost allocation, compliance)
       ignore_changes = [tags]
     }
   }
   ```

3. **Ignore one-time configuration:**
   ```hcl
   resource "aws_key_pair" "deployer" {
     key_name   = "deployer-key"
     public_key = file("~/.ssh/id_rsa.pub")
     
     lifecycle {
       # Public key cannot be changed after creation
       # Ignore to prevent replacement
       ignore_changes = [public_key]
     }
   }
   ```

4. **Ignore ASG-managed changes:**
   ```hcl
   resource "aws_autoscaling_group" "app" {
     # ...
     desired_capacity = 3
     
     lifecycle {
       # Auto Scaling changes desired_capacity based on metrics
       # Ignore to prevent Terraform reverting changes
       ignore_changes = [desired_capacity]
     }
   }
   ```

**DevOps Best Practices:**

1. **Document why changes are ignored:**
   ```hcl
   resource "aws_db_instance" "main" {
     # Database minor version updated by AWS during maintenance window
     # Ignoring prevents Terraform from reverting to planned version
     
     lifecycle {
       ignore_changes = [engine_version]
     }
   }
   ```

2. **Use targeted ignore_changes, not all:**
   ```hcl
   # ❌ WRONG - Ignores all changes, including critical ones
   resource "aws_instance" "app" {
     lifecycle {
       ignore_changes = all
     }
   }
   
   # ✅ CORRECT - Ignore only specific attributes
   resource "aws_instance" "app" {
     lifecycle {
       ignore_changes = [
         credit_specification,  # T3 unlimited credits
         cpu_credits            # Auto-managed
       ]
     }
   }
   ```

3. **Validate that ignored attributes don't affect functionality:**
   ```hcl
   # ❌ PROBLEM - Ignoring critical attribute
   resource "aws_security_group" "app" {
     # ... rules ...
     
     lifecycle {
       ignore_changes = [description]  # Fine, metadata only
     }
   }
   
   # ❌ WRONG - Ignoring functional attribute
   resource "aws_security_group" "app" {
     lifecycle {
       ignore_changes = [ingress]  # WRONG - ignores security rules!
     }
   }
   ```

**Common Pitfalls:**

1. **ignore_changes prevents necessary updates:**
   ```hcl
   # ❌ PROBLEM - Prevents updating RDS password when rotated
   variable "db_password" {
     type      = string
     sensitive = true
   }
   
   resource "aws_db_instance" "main" {
     master_password = var.db_password
     
     lifecycle {
       ignore_changes = [master_password]  # ❌ Secrets stuck
     }
   }
   
   # ✅ CORRECT - Only ignore if managed externally
   # If you manage password rotation in AWS Secrets Manager,
   # then ignoring makes sense
   ```

2. **Relying on ignore_changes instead of fixing root cause:**
   ```hcl
   # ❌ WRONG - Masking a problem
   resource "aws_instance" "app" {
     # External system changing tags
     tags = var.tags
     
     lifecycle {
       ignore_changes = [tags]  # Hiding the real issue
     }
   }
   
   # ✅ CORRECT - Fix root cause
   # Option 1: Use native tagging from AWS service
   # Option 2: Use aws_ec2_tag resource instead
   # Option 3: Coordinate with external tagging system
   ```

#### Practical Code Examples

```hcl
# Example: Production database with external management

variable "enable_maintenance_window" {
  type    = bool
  default = true
}

variable "db_version" {
  type = string
}

resource "aws_db_instance" "production" {
  identifier           = "production-db"
  engine               = "postgres"
  engine_version       = var.db_version
  allocated_storage    = 100
  
  backup_retention_period = 30
  backup_window          = "03:00-04:00"
  maintenance_window     = "mon:04:00-mon:05:00"
  
  # Enable automatic minor version updates
  auto_minor_version_upgrade = true
  
  tags = {
    Environment = "production"
    Team        = "platform"
    Compliance  = "sox"
  }
  
  lifecycle {
    # AWS updates minor versions automatically
    # Ignore to prevent Terraform reverting changes
    ignore_changes = [
      engine_version,  # AWS updates in maintenance window
    ]
    
    # Prevent accidental deletion
    prevent_destroy = true
  }
}

# Separate resource for critical tag updates
resource "aws_ec2_tag" "production_compliance" {
  resource_id = aws_db_instance.production.resource_id
  key         = "LastSecurityAudit"
  value       = formatdate("YYYY-MM-DD", timestamp())
}

output "db_endpoint" {
  value = aws_db_instance.production.endpoint
}

# Deployment notes:
# 1. AWS maintains engine_version independently
# 2. Terraform plan will show engine_version changes (ignored)
# 3. No errors or conflicts occur
# 4. Manual role-forward occurs without Terraform intervention
```

---

## 6. Dependency Handling

### 6.1 Implicit Dependencies

#### Textual Deep Dive

**Architecture Role:**
Terraform automatically detects dependencies when resources reference each other's attributes. Implicit dependencies enable cleaner code and automatic ordering, but can create brittle configurations if not managed carefully.

**Internal Working Mechanism:**

```
Resource Attribute References
       │
       ├─ aws_instance.app.id
       ├─ aws_subnet.main.id
       └─ aws_security_group.web.id
       │
       ▼
Dependency Graph Construction
├── Parser detects references
├── Creates edges in DAG
├── Topological sort determines order
│
       ▼
Execution Plan
└── Respect dependency order during apply
```

**Reference Types:**

```hcl
# Direct attribute reference (creates implicit dependency)
resource "aws_instance" "app" {
  subnet_id = aws_subnet.main.id  # Implicit dependency on aws_subnet.main
}

# Splat reference (all attributes)
resource "aws_lb_target_group_attachment" "app" {
  for_each     = { for idx, instance in aws_instance.app : idx => instance }
  target_id    = each.value.id
}

# Conditional reference
resource "aws_route" "main" {
  depends_on = aws_nat_gateway.main  # Explicit, not implicit
}

# Collection references
locals {
  instance_ids = aws_instance.app[*].id  # Depends on all instances
}
```

**Production Usage Patterns:**

1. **Automatic ordering through references:**
   ```hcl
   # VPC is created first
   resource "aws_vpc" "main" {
     cidr_block = "10.0.0.0/16"
   }
   
   # Subnet creation depends on VPC (implicit)
   resource "aws_subnet" "main" {
     vpc_id     = aws_vpc.main.id  # Implicit dependency
     cidr_block = "10.0.1.0/24"
   }
   
   # Instance creation depends on VPC → Subnet (implicit chain)
   resource "aws_instance" "app" {
     subnet_id = aws_subnet.main.id  # Indirect dependency on VPC
   }
   ```

2. **Security group dependencies:**
   ```hcl
   resource "aws_security_group" "main" {
     vpc_id = aws_vpc.main.id
   }
   
   # Rule depends on security group (implicit)
   resource "aws_security_group_rule" "allow_http" {
     security_group_id = aws_security_group.main.id
     from_port         = 80
   }
   ```

3. **Complex dependencies through locals:**
   ```hcl
   # All instances must exist before load balancer config
   locals {
     instance_ids = aws_instance.app[*].id  # Implicit dependency on all instances
   }
   
   resource "aws_lb_target_group" "main" {
     # Doesn't directly depend on instances,
     # but can be updated based on count changes
   }
   ```

**DevOps Best Practices:**

1. **Use implicit dependencies when possible:**
   ```hcl
   # ✅ CORRECT - Clear implicit dependency
   resource "aws_instance" "app" {
     subnet_id         = aws_subnet.main.id  # Implicit
     security_groups   = [aws_security_group.app.id]  # Implicit
   }
   
   # ❌ UNNECESSARY - Explicit when implicit exists
   resource "aws_instance" "app" {
     subnet_id = aws_subnet.main.id
     
     depends_on = [aws_subnet.main]  # Redundant!
   }
   ```

2. **Avoid creating dependencies on logic rather than resources:**
   ```hcl
   # ✅ CORRECT - Dependency on actual resource
   resource "aws_security_group_rule" "allow_app" {
     depends_on = [aws_security_group.app]
   }
   
   # ❌ WRONG - Dependency on condition
   resource "aws_security_group_rule" "allow_app" {
     depends_on = [var.enable_rules ? aws_security_group.app : null]
   }
   ```

**Common Pitfalls:**

1. **Implicit dependencies break with refactoring:**
   ```hcl
   # Original code
   resource "aws_instance" "app" {
     subnet_id = aws_subnet.main.id
   }
   
   # Refactoring subnet creation into module
   module "networking" {
     source = "./modules/networking"
   }
   
   # ❌ BROKEN - Instance still references old resource
   resource "aws_instance" "app" {
     subnet_id = aws_subnet.main.id  # aws_subnet.main no longer exists!
   }
   
   # ✅ FIX - Update reference
   resource "aws_instance" "app" {
     subnet_id = module.networking.subnet_id
   }
   ```

2. **Circular dependencies from implicit references:**
   ```hcl
   # ❌ PROBLEM - Circular dependency
   resource "aws_instance" "app" {
     subnet_id = aws_subnet.main.id
   }
   
   resource "aws_subnet" "main" {
     # Some attribute depends on instance (circular)
   }
   ```

#### Practical Code Examples

```hcl
# Example: Implicit dependency chains

# Tier 1: Base infrastructure (no dependencies)
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags = { Name = "main-vpc" }
}

# Tier 2: Depends on VPC
resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.main.id  # Implicit dependency
  cidr_block        = "10.0.${count.index + 1}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  
  tags = { Name = "private-subnet-${count.index + 1}" }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  # Implicit dependency
  
  tags = { Name = "main-igw" }
}

# Tier 3: Depends on VPC + Subnets
resource "aws_security_group" "app" {
  vpc_id = aws_vpc.main.id  # Implicit on VPC
  
  tags = { Name = "app-sg" }
}

# Tier 4: Depends on previous tiers
resource "aws_instance" "app" {
  count                = 3
  ami                  = data.aws_ami.amazon_linux_2.id
  instance_type        = "t3.medium"
  subnet_id            = aws_subnet.private[count.index].id  # Implicit on subnets
  vpc_security_group_ids = [aws_security_group.app.id]     # Implicit on security group
  
  tags = { Name = "app-${count.index + 1}" }
}

# Tier 5: Depends on instances
resource "aws_lb_target_group_attachment" "app" {
  count            = 3
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.app[count.index].id  # Implicit on instances
  port             = 80
}

# Dependency visualization:
# VPC
# ├── Subnet
# ├── IGW
# └── SecurityGroup
#     └── Instance
#         └── LB Target Attachment

output "dependency_graph" {
  value = "See diagram above"
}
```

---

### 6.2 Explicit Dependencies (depends_on)

#### Textual Deep Dive

**Architecture Role:**
`depends_on` creates explicit dependencies when implicit references don't exist, ensuring proper ordering for side-effect dependencies, API rate limiting, or sequential operations that aren't tied to attribute sharing.

**When Implicit Dependencies Don't Capture Intent:**

```
Scenario 1: Attribute Sharing (Implicit)
├─ Resource A creates attribute
└─ Resource B references attribute → Dependency clear

Scenario 2: Side Effects (Explicit needed)
├─ Resource A modifies cloud configuration
├─ Resource B depends on side effect (not attributes)
└─ Must use depends_on
```

**Internal Working Mechanism:**

```
depends_on = [resource_type.name]
       │
       ▼
Graph Edge Creation
├── Adds dependency edge even without attribute reference
└── Affects execution ordering

       ▼
Execution Plan
└── Resource only applied after dependencies satisfied
```

**Production Usage Patterns:**

1. **API rate limiting / operational ordering:**
   ```hcl
   # Create first VPC
   resource "aws_vpc" "main" {
     cidr_block = "10.0.0.0/16"
   }
   
   # Create second VPC, but stagger creation to avoid API throttling
   resource "aws_vpc" "secondary" {
     cidr_block = "10.1.0.0/16"
     
     depends_on = [aws_vpc.main]  # Wait for main VPC creation
   }
   ```

2. **Conditional IAM role attachment:**
   ```hcl
   resource "aws_iam_role" "app" {
     assume_role_policy = jsonencode({...})
   }
   
   resource "aws_iam_role_policy_attachment" "app_policy" {
     role       = aws_iam_role.app.name
     policy_arn = aws_iam_policy.app.arn
   }
   
   # EC2 instance must wait for IAM role to be fully prepared
   # (including policy attachment)
   resource "aws_instance" "app" {
     iam_instance_profile = aws_iam_instance_profile.app.name
     
     depends_on = [
       aws_iam_role_policy_attachment.app_policy,  # Explicit!
       # Without depends_on, instance launches before policy attached
     ]
   }
   ```

3. **VPN gateway readiness:**
   ```hcl
   resource "aws_vpn_gateway" "main" {
     vpc_id = aws_vpc.main.id
   }
   
   # VPN gateway attachment creates side effects in routing
   resource "aws_vpn_gateway_attachment" "main" {
     vpc_id         = aws_vpc.main.id
     vpn_gateway_id = aws_vpn_gateway.main.id
   }
   
   # Routes must wait for VPN fully attached
   resource "aws_route" "vpn_route" {
     route_table_id            = aws_route_table.main.id
     destination_cidr_block    = "192.168.0.0/16"  # Remote network
     gateway_id                = aws_vpn_gateway.main.id
     
     depends_on = [aws_vpn_gateway_attachment.main]  # Explicit!
   }
   ```

4. **Graceful service startup order:**
   ```hcl
   # Database must be healthy before application starts
   resource "aws_db_instance" "main" {
     allocated_storage = 100
   }
   
   # Application depends on database readiness
   resource "aws_instance" "app" {
     user_data = "#!/bin/bash\necho 'Starting app'\n"
     
     depends_on = [aws_db_instance.main]  # Wait for DB
   }
   ```

**DevOps Best Practices:**

1. **Prefer implicit when possible, explicit only when necessary:**
   ```hcl
   # ✅ IMPLICIT - Cleaner and self-documenting
   resource "aws_instance" "app" {
     subnet_id = aws_subnet.main.id
   }
   
   # ⚠️ EXPLICIT - Use only for non-attribute dependencies
   resource "aws_instance" "app" {
     depends_on = [aws_iam_role_policy_attachment.app]
   }
   ```

2. **Document why explicit dependency is needed:**
   ```hcl
   resource "aws_instance" "app" {
     # Must wait for IAM role policies to be fully attached
     # before instance can access other AWS services
     depends_on = [aws_iam_role_policy_attachment.app]
   }
   ```

3. **Use for meta-arguments, not alternatives to attributes:**
   ```hcl
   # ❌ WRONG - subnet_id already creates dependency
   resource "aws_instance" "app" {
     subnet_id  = aws_subnet.main.id
     depends_on = [aws_subnet.main]  # Redundant!
   }
   
   # ✅ CORRECT - Only depends_on for non-attribute deps
   resource "aws_instance" "app" {
     subnet_id = aws_subnet.main.id
     
     depends_on = [
       aws_iam_instance_profile.app_profile,  # Non-attribute dependency
     ]
   }
   ```

**Common Pitfalls:**

1. **Over-using depends_on creates artificial bottlenecks:**
   ```hcl
   # ❌ WRONG - Forces sequential creation
   resource "aws_instance" "web_1" {
     # ...
   }
   
   resource "aws_instance" "web_2" {
     depends_on = [aws_instance.web_1]  # Unnecessary!
   }
   
   resource "aws_instance" "web_3" {
     depends_on = [aws_instance.web_2]  # Creates serial chain
   }
   
   # ✅ CORRECT - Parallel is fine for independent resources
   resource "aws_instance" "web" {
     count = 3  # All created in parallel
   }
   ```

2. **depends_on with count/for_each requires specificity:**
   ```hcl
   # ❌ AMBIGUOUS - Which index?
   resource "aws_instance" "app" {
     count      = 3
     depends_on = [aws_security_group.main]  # Actually means all instances
   }
   
   # ✅ EXPLICIT - Clear which resource
   resource "aws_instance" "app" {
     count      = 3
     depends_on = [aws_security_group.main]  # Depends on SG, not other instances
   }
   ```

**Common Pitfalls (continued):**

3. **Ignoring implicit dependencies when adding depends_on:**
   ```hcl
   # ⚠️ PROBLEM - Are these all necessary?
   resource "aws_instance" "app" {
     subnet_id = aws_subnet.main.id  # Implicit on subnet
     
     depends_on = [
       aws_vpc.main,             # Implicit via subnet
       aws_subnet.main,          # Redundant!
       aws_security_group.app,   # Explicit (good)
     ]
   }
   ```

#### Practical Code Examples

```hcl
# Example: Multi-region setup with explicit ordering

terraform {
  required_providers {
    aws = [
      { alias = "primary" }
      { alias = "secondary" }
    ]
  }
}

# Primary region infrastructure
resource "aws_vpc" "primary" {
  provider   = aws.primary
  cidr_block = "10.0.0.0/16"
  
  tags = { Name = "primary-vpc" }
}

# Secondary region infrastructure - wait for primary
resource "aws_vpc" "secondary" {
  provider   = aws.secondary
  cidr_block = "10.1.0.0/16"
  
  # Stagger creation to avoid API rate limits
  depends_on = [aws_vpc.primary]
  
  tags = { Name = "secondary-vpc" }
}

# Create VPN between regions
resource "aws_vpn_gateway" "primary" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id
}

resource "aws_vpn_gateway_attachment" "primary" {
  provider       = aws.primary
  vpc_id         = aws_vpc.primary.id
  vpn_gateway_id = aws_vpn_gateway.primary.id
}

# Route must wait for VPN to be fully attached
resource "aws_route" "to_secondary" {
  provider               = aws.primary
  route_table_id         = aws_route_table.primary.id
  destination_cidr_block = aws_vpc.secondary.cidr_block
  gateway_id             = aws_vpn_gateway.primary.id
  
  depends_on = [aws_vpn_gateway_attachment.primary]
}

output "vpn_configured" {
  value = true
  depends_on = [aws_route.to_secondary]
}
```

---

### 6.3 Implicit vs. Explicit: Decision Matrix

####  Decision Guide

| Scenario | Use Implicit | Use Explicit | Reason |
|----------|-------------|-------------|--------|
| Resource shares attributes | ✅ Yes | ❌ No | Reference creates dependency automatically |
| API side effects | ❌ No | ✅ Yes | Side effects not reflected in attributes |
| Rate limiting / sequencing | ❌ No | ✅ Yes | Control timing without attribute coupling |
| IAM policy attachment order | ❌ No | ✅ Yes | Policy must attach before resource uses role |
| Circular would occur | ❌ No | ✅ Yes if needed | Explicit can break cycles if carefully used |
| For documentation | ❌ No | ⚠️ Maybe | Over-documenting can obscure logic |

---

---

## 7. Hands-on Scenarios

### Scenario 1: Multi-Environment Infrastructure with Progressive Scaling

**Problem Statement:**
Your organization needs to deploy a three-tier application (web, API, database) across dev, staging, and production environments. Requirements:
- Each environment has different sizing and feature activation
- Production requires disaster recovery
- Zero-downtime updates for web tier
- Development can be destroyed without constraints
- Costs must be optimized for non-production tiers

**Solution Architecture:**

```
environments/
├── dev/
│   ├── terraform.tfvars
│   └── main.tf (calls root module)
├── staging/
│   ├── terraform.tfvars
│   └── main.tf
├── prod/
│   ├── terraform.tfvars
│   └── main.tf
└── terraform/
    ├── variables.tf
    ├── main.tf
    ├── outputs.tf
    ├── modules/
    │   ├── networking/
    │   ├── compute/
    │   └── database/
    └── locals.tf
```

**Implementation:**

```hcl
# terraform/variables.tf
variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}

variable "instance_count" {
  type    = number
  default = 1
}

variable "enable_disaster_recovery" {
  type    = bool
  default = false
}

variable "enable_detailed_monitoring" {
  type    = bool
  default = false
}

# terraform/locals.tf
locals {
  is_prod    = var.environment == "prod"
  is_staging = var.environment == "staging"
  is_dev     = var.environment == "dev"
  
  # Environment sizing
  compute_config = {
    dev = {
      web_instance_type = "t3.micro"
      web_count         = 1
      api_instance_type = "t3.micro"
      api_count         = 1
      monitoring        = false
    }
    staging = {
      web_instance_type = "t3.small"
      web_count         = 2
      api_instance_type = "t3.small"
      api_count         = 2
      monitoring        = true
    }
    prod = {
      web_instance_type = "m5.large"
      web_count         = 4
      api_instance_type = "m5.large"
      api_count         = 3
      monitoring        = true
    }
  }[var.environment]
  
  db_config = {
    dev = {
      instance_class      = "db.t3.micro"
      allocated_storage   = 20
      backup_retention    = 7
      multi_az            = false
      storage_encrypted   = false
    }
    staging = {
      instance_class      = "db.t3.small"
      allocated_storage   = 100
      backup_retention    = 14
      multi_az            = false
      storage_encrypted   = true
    }
    prod = {
      instance_class      = "db.m5.large"
      allocated_storage   = 500
      backup_retention    = 30
      multi_az            = true
      storage_encrypted   = true
    }
  }[var.environment]
  
  tags = {
    Environment = var.environment
    ManagedBy   = "Terraform"
    CreatedAt   = formatdate("YYYY-MM-DD", timestamp())
  }
}

# terraform/main.tf
module "networking" {
  source = "./modules/networking"
  
  environment = var.environment
  tags        = local.tags
}

module "compute" {
  source = "./modules/compute"
  
  environment          = var.environment
  web_instance_type    = local.compute_config.web_instance_type
  web_instance_count   = local.compute_config.web_count
  api_instance_type    = local.compute_config.api_instance_type
  api_instance_count   = local.compute_config.api_count
  enable_monitoring    = local.compute_config.monitoring || var.enable_detailed_monitoring
  subnet_ids           = module.networking.private_subnet_ids
  security_group_id    = module.networking.app_sg_id
  tags                 = local.tags
}

module "database" {
  source = "./modules/database"
  
  environment          = var.environment
  instance_class       = local.db_config.instance_class
  allocated_storage    = local.db_config.allocated_storage
  backup_retention     = local.db_config.backup_retention
  multi_az             = local.db_config.multi_az
  storage_encrypted    = local.db_config.storage_encrypted
  subnet_ids           = module.networking.db_subnet_ids
  security_group_id    = module.networking.db_sg_id
  tags                 = local.tags
}

# DR: Read replica for production only
module "database_replica" {
  count  = local.is_prod && var.enable_disaster_recovery ? 1 : 0
  source = "./modules/database-replica"
  
  primary_db_id = module.database.db_instance_id
  tags          = local.tags
}

# terraform/outputs.tf
output "application_endpoint" {
  value       = module.compute.load_balancer_dns
  description = "Load balancer endpoint for application"
}

output "database_endpoint" {
  value       = module.database.db_endpoint
  description = "RDS database endpoint"
}

output "has_disaster_recovery" {
  value = length(module.database_replica) > 0
}

# environments/prod/terraform.tfvars
environment                  = "production"
instance_count              = 4
enable_disaster_recovery    = true
enable_detailed_monitoring  = true

# environments/staging/terraform.tfvars
environment                 = "staging"
instance_count             = 2
enable_disaster_recovery   = false
enable_detailed_monitoring = true

# environments/dev/terraform.tfvars
environment                = "development"
instance_count            = 1
enable_disaster_recovery  = false
enable_detailed_monitoring = false

# modules/compute/main.tf (excerpt showing zero-downtime update pattern)
resource "aws_instance" "web" {
  count         = var.web_instance_count
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = var.web_instance_type
  subnet_id     = var.subnet_ids[count.index % length(var.subnet_ids)]
  security_groups = [var.security_group_id]
  
  monitoring = var.enable_monitoring
  
  # Zero-downtime updates
  lifecycle {
    create_before_destroy = !contains(["dev"], var.environment)
    # Development can have downtime; prod/staging cannot
  }
  
  tags = merge(var.tags, { Name = "${var.environment}-web-${count.index + 1}" })
}

# Deployment
# cd environments/prod
# terraform init -backend-config="key=prod/terraform.tfstate"
# terraform plan -var-file="terraform.tfvars"
# terraform apply -var-file="terraform.tfvars"
```

---

### Scenario 2: Managing Immutable Database Updates with Minimal Downtime

**Problem Statement:**
You need to upgrade your RDS PostgreSQL from version 13 to version 15. The upgrade requires a new instance (immutable attribute), but your application cannot tolerate downtime exceeding 5 minutes.

**Solution:**

```hcl
variable "database_version" {
  type    = string
  default = "13.7"
}

variable "enable_new_database" {
  type    = bool
  default = false
  description = "When true, creates new DB and switches traffic"
}

# Old database - keep during transition
resource "aws_db_instance" "main_v1" {
  count      = !var.enable_new_database ? 1 : 0
  identifier = "app-database-v1"
  engine_version = "13.7"
  
  lifecycle {
    prevent_destroy = true
  }
}

# New database - created alongside old
resource "aws_db_instance" "main_v2" {
  count      = var.enable_new_database ? 1 : 0
  identifier = "app-database-v2"
  engine_version = "15"
  
  # Restore from old database snapshot
  snapshot_identifier = var.database_snapshot_id
}

# Application configuration switches based on enable_new_database
locals {
  database_endpoint = var.enable_new_database ? aws_db_instance.main_v2[0].endpoint : aws_db_instance.main_v1[0].endpoint
}

# Application instances reference current database
resource "aws_instance" "app" {
  count = 3
  user_data = file("${path.module}/bootstrap.sh")
  
  environment {
    DATABASE_URL = "postgresql://user:pass@${local.database_endpoint}:5432/myapp"
  }
  
  # Depends on current database being ready
  depends_on = [
    var.enable_new_database ? aws_db_instance.main_v2[0] : aws_db_instance.main_v1[0]
  ]
}

# Deployment workflow:
# 1. Create snapshot of v1
# 2. terraform apply -var="database_snapshot_id=snap-xxxxx" -var="enable_new_database=true"
# 3. Monitor application health
# 4. terraform apply -var="enable_new_database=true" (switches traffic)
# 5. Delete old database after testing
```

---

## 8. Interview Questions

### Foundational Level (5-7 years experience)

**Q1: Can you walk us through how Terraform handles variable precedence?**

*Expected Answer:*
Terraform evaluates variables in this order (highest to lowest):
1. CLI flags (`-var 'key=value'`)
2. Environment variables (`TF_VAR_*`)
3. `.tfvars` files (terraform.tfvars, custom.tfvars)
4. Variable default values

This allows CI/CD systems to override environment-specific values without modifying source files. I typically organize dev/staging/prod via separate .tfvars files in a structured layout.

---

**Q2: What's the difference between `count` and `for_each`, and when would you use each?**

*Expected Answer:*
**Count**: Uses numeric indices (0, 1, 2). Good for simple scaling but fragile if removing items (index shifts).
**For_each**: Uses string keys (map/set). Stable when removing items because keys don't shift.

I prefer `for_each` for production because removing a configuration item doesn't destroy other instances. `count` is acceptable for truly dynamic scenarios where order doesn't matter.

Example:
```hcl
# for_each - semantic, stable
for_each = {
  web    = "t3.small"
  api    = "m5.medium"
  worker = "t3.large"
}

# count - numeric, simpler for homogeneous resources
count = 5  # 5 identical instances
```

---

**Q3: Explain the difference between implicit and explicit dependencies.**

*Expected Answer:*
**Implicit**: Terraform detects dependencies when resources reference attributes. Example: `subnet_id = aws_subnet.main.id` creates an implicit dependency on aws_subnet.main.

**Explicit**: `depends_on` meta-argument tells Terraform about dependencies not reflected in attributes. Used when there are side effects or API rate limiting concerns.

Best practice: Use implicit when possible (cleaner), explicit only for non-attribute dependencies like IAM role policy attachment before EC2 instance creation.

---

**Q4: When would you use `ignore_changes` and what are the risks?**

*Expected Answer:*
`ignore_changes` tells Terraform to ignore detected changes to specific attributes. Use cases:
- Attributes changed by external systems (auto-scaling modifying desired_capacity)
- Cloud provider automations (AWS patching RDS minor versions)
- One-time configurations that cannot be changed

Risks:
- Can mask important configuration drift
- Prevents necessary updates
- Makes state inconsistent with actual infrastructure

I only use it when I understand why changes are happening externally and have verified they shouldn't be Terraform-managed.

---

**Q5: Design a multi-environment infrastructure with dev, staging, and production. How would you structure it?**

*Expected Answer:*
```
terraform/
├── environments/{dev,staging,prod}/
│   ├── terraform.tfvars (env-specific values)
│   └── main.tf (calls root module)
├── modules/
│   ├── networking/
│   ├── compute/
│   └── database/
├── variables.tf
├── main.tf
└── outputs.tf
```

Key points:
- Single codebase, multiple .tfvars files per environment
- Module-based for reusability
- Variables enable environment-specific behavior (sizing, redundancy)
- Remote state per environment with locking
- Validation ensures data consistency

---

### Advanced Level (7-10+ years experience)

**Q6: You have a stateless web application deployed on EC2 with 10 instances. You need to upgrade the AMI without downtime. Walk us through your approach.**

*Expected Answer:*
I'd use `create_before_destroy` with a load balancer:

```hcl
resource "aws_instance" "web" {
  count         = 10
  ami           = var.ami_id  # Updated to new AMI
  instance_type = "t3.large"
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_lb_target_group_attachment" "web" {
  count            = 10
  target_group_arn = aws_lb_target_group.app.arn
  target_id        = aws_instance.web[count.index].id
  # No explicit lifecycle needed; LB auto-detects new instances
}
```

Terraform will:
1. Create 10 new instances with updated AMI
2. Stagger registration with load balancer
3. Destroy old instances
4. Throughout: LB routes traffic only to healthy instances

Cost consideration: Temporarily 20 instances running. Need 2x capacity during update.

---

**Q7: Your production RDS instance has a critical attribute error (e.g., parameter_group_name). Changing it requires replacing the entire database. How would you handle this?**

*Expected Answer:*
This requires blue-green deployment:

```hcl
variable "enable_new_db" {
  type    = bool
  default = false
}

# Old database - kept safe during transition
resource "aws_db_instance" "main_current" {
  count               = !var.enable_new_db ? 1 : 0
  identifier          = "prod-db"
  parameter_group_name = "incompatible-group"
  backup_retention_period = 30
  
  lifecycle {
    prevent_destroy = true
  }
}

# New database with correct parameter group
resource "aws_db_instance" "main_new" {
  count               = var.enable_new_db ? 1 : 0
  identifier          = "prod-db-new"
  parameter_group_name = "correct-group"
  snapshot_identifier = aws_db_instance.main_current[0].latest_restorable_time  # From backup
}

locals {
  db_endpoint = var.enable_new_db ? aws_db_instance.main_new[0].endpoint : aws_db_instance.main_current[0].endpoint
}
```

Workflow:
1. Create snapshot from production
2. `terraform apply -var="enable_new_db=true"` (new DB created in parallel)
3. Test application against new DB
4. Switch application traffic (update connection strings)
5. Monitor old DB for issues
6. Remove old DB after validation period

Downtime: Only the connection string update (seconds, not hours).

---

**Q8: You're managing infrastructure across multiple AWS regions with disaster recovery failover. Design the dependency strategy.**

*Expected Answer:*
```hcl
# Primary region
module "primary_region" {
  source = "./modules/region"
  providers = {
    aws = aws.primary
  }
  
  region                 = "us-east-1"
  enable_database        = true
  enable_read_replica_in = "us-west-2"
}

# Secondary region (standby)
module "secondary_region" {
  source = "./modules/region"
  providers = {
    aws = aws.secondary
  }
  
  region                      = "us-west-2"
  enable_database             = false  # DR only
  enable_read_replica_target  = true   # Receives replica from primary
  
  # Stagger creation to allow primary to establish first
  depends_on = [module.primary_region]
}

# Failover logic
locals {
  active_region_endpoint = var.failover_to_dr ? module.secondary_region.db_endpoint : module.primary_region.db_endpoint
}

resource "aws_instance" "app" {
  # Application connects to active region's database
  user_data = "export DB_ENDPOINT=${local.active_region_endpoint}"
}
```

Key aspects:
- **Explicit depends_on** prevents simultaneous region creation (API limits)
- **Read replica** in secondary region is always up-to-date
- **Failover variable** switches traffic without destroying primary
- **Route53** health checks trigger failover decision
- **Asymmetric configuration**: Primary active, secondary standby

---

**Q9: Walk us through the lifecycle rules and when each is appropriate.**

*Expected Answer:*

| Rule | Use Case | Example |
|------|----------|---------|
| `prevent_destroy` | Critical data stores | RDS production database |
| `create_before_destroy` | Stateless scaling | EC2 auto-scaling groups |
| `ignore_changes` | External mutations | AWS auto-patched RDS versions |

Best practice: Understand *why* a rule is needed:
- `prevent_destroy`: Prevents human error before code review
- `create_before_destroy`: Enables zero-downtime updates with load balancing
- `ignore_changes`: Reduces false-positive drifts from non-Terraform systems

Over-using lifecycle rules suggests design issues. If you have many suppress rules, consider whether these should be managed by different systems.

---

**Q10: Design a variable validation strategy that prevents invalid configurations from reaching production.**

*Expected Answer:*
```hcl
variable "instance_count" {
  type    = number
  
  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 100
    error_message = "Count must be 1-100."
  }
}

variable "environment" {
  type = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod."
  }
}

variable "database_version" {
  type = string
  
  validation {
    condition     = can(regex("^(13|14|15|16)\\.[0-9]+$", var.database_version))
    error_message = "Database version must match 13.x, 14.x, 15.x, or 16.x."
  }
}

# Complex cross-variable validation
variable "autoscaling_config" {
  type = object({
    min_size = number
    max_size = number
    desired  = number
  })
  
  validation {
    condition = (
      var.autoscaling_config.min_size <= var.autoscaling_config.desired &&
      var.autoscaling_config.desired <= var.autoscaling_config.max_size &&
      var.autoscaling_config.min_size >= 1 &&
      var.autoscaling_config.max_size <= 100
    )
    error_message = "ASG sizing must be: min ≤ desired ≤ max, all within 1-100."
  }
}
```

Benefit: Validation happens at plan time before resources are created, catching misconfigurations early in CI/CD pipelines.

---

## Document Status

- **Document Version**: 2.0
- **Last Updated**: 2026-03-07
- **Completion Status**: All planned sections complete
  - ✅ Section 1: Introduction
  - ✅ Section 2: Foundational Concepts
  - ✅ Section 3: Terraform Variables and Outputs
  - ✅ Section 4: Provisioning Patterns
  - ✅ Section 5: Lifecycle Management
  - ✅ Section 6: Dependency Handling
  - ✅ Section 7: Hands-on Scenarios
  - ✅ Section 8: Interview Questions

**Target Audience**: Senior DevOps Engineers (5-10+ years experience)

**Key Topics Covered**:
- Variable management and validation strategies
- Local values and computed configuration
- Multi-environment .tfvars structures
- Output design as module API contracts
- Conditional expressions for dynamic infrastructure
- Count and for_each patterns
- Dynamic blocks for reducing boilerplate
- Lifecycle rules (prevent_destroy, create_before_destroy, ignore_changes)
- Implicit and explicit dependency management
- Real-world deployment scenarios
- Interview-ready technical depth

**Recommended Next Steps**:
- Hands-on Scenario practice in test environments
- Review interview questions with team leads
- Consider creating environment-specific study guides
- Implement code examples in your organization's infrastructure

---

**Document License**: Educational Material - Distribution and modification permitted with appropriate attribution.

**Questions or Updates**: For suggested improvements or corrections, please submit via organization documentation feedback process.

