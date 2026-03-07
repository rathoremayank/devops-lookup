# Terraform Secrets Management, Cloud/Enterprise & Multi-environment Strategies

## Table of Contents

1. [Introduction](#introduction)
   - [Overview of Topic](#overview-of-topic)
   - [Real-world Production Use Cases](#real-world-production-use-cases)
   - [Cloud Architecture Context](#cloud-architecture-context)

2. [Foundational Concepts](#foundational-concepts)
   - [Architecture Fundamentals](#architecture-fundamentals)
   - [DevOps Principles](#devops-principles)
   - [Best Practices Framework](#best-practices-framework)
   - [Common Misunderstandings](#common-misunderstandings)

3. [Terraform Secrets Management](#terraform-secrets-management)
   - [Principles of Secrets in Infrastructure](#principles-of-secrets-in-infrastructure)
   - [Vault Integration](#vault-integration)
   - [AWS Systems Manager Parameter Store](#aws-systems-manager-parameter-store)
   - [Environment Variables](#environment-variables)
   - [Sensitive Variables](#sensitive-variables)
   - [Secure Backends](#secure-backends)

4. [Terraform Cloud/Enterprise](#terraform-cloudenterprise)
   - [Workspace Management](#workspace-management)
   - [Remote Execution](#remote-execution)
   - [Policy as Code](#policy-as-code)
   - [Run Workflows](#run-workflows)
   - [Collaboration Features](#collaboration-features)

5. [Multi-environment Strategies](#multi-environment-strategies)
   - [Workspace Strategies](#workspace-strategies)
   - [Directory Structure Patterns](#directory-structure-patterns)
   - [Variable Management Across Environments](#variable-management-across-environments)
   - [Promotion Models](#promotion-models)
   - [Best Practices](#best-practices)

6. [Hands-on Scenarios](#hands-on-scenarios)

7. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

This study guide covers three interconnected pillars of enterprise Terraform operations that distinguish senior DevOps practitioners:

**Terraform Secrets Management** addresses the critical challenge of protecting sensitive data (API keys, database credentials, certificates) throughout the infrastructure-as-code lifecycle. Senior engineers understand that secrets management is not a checkbox item but a layered strategy encompassing encryption, access control, rotation, and audit trails.

**Terraform Cloud/Enterprise** represents the organizational layer that enables teams to scale IaC practices beyond local development. It provides governance, collaboration, and consistency mechanisms essential for multi-team, multi-project environments where local execution becomes unmaintainable.

**Multi-environment Strategies** solve the practical problem of maintaining consistency across development, staging, and production environments while allowing legitimate variation. This requires systematic approaches to code organization, variable management, and promotion workflows that prevent drift and configuration errors.

Together, these three areas form the backbone of production Terraform implementations at scale.

### Real-world Production Use Cases

#### Use Case 1: Financial Services - Regulatory Compliance at Scale
A fintech firm manages 500+ microservices across 8 AWS accounts with PCI-DSS compliance requirements. They implement:
- HashiCorp Vault for dynamic credentials with TTL-based rotation
- Terraform Cloud workspaces for each account with policy enforcement preventing unapproved resource types
- Separate tfvars per environment with encrypted backends using AWS KMS
- Audit trail through Terraform Cloud's run history, Vault logs, and AWS CloudTrail

**Challenge Addressed**: Proving to auditors that infrastructure changes are approved, encrypted, and logged without storing plaintext credentials in state files.

#### Use Case 2: SaaS Platform - Development Velocity Without Security Compromise
A SaaS company with 50+ developers deploying infrastructure changes daily:
- Environment variables injected at Terraform Cloud execution with access restricted by team
- Directory structure: `infrastructure/{service}/{environment}/{main.tf, variables.tf}`
- Sentinel policies enforcing tag requirements, resource naming conventions, cost controls
- Automated promotion: dev → staging (automatic) → production (requires approval)

**Challenge Addressed**: Enabling developer autonomy while preventing security or cost incidents through policy enforcement rather than code review bottlenecks.

#### Use Case 3: Enterprise Migration - Parallel Environments with State Isolation
A legacy enterprise migrating to Terraform:
- Original infrastructure in AWS (manual), migrating parallel environment simultaneously
- Separate backends and workspaces for old vs. new infrastructure to prevent accidental destruction
- Variables organized to support A/B testing deployments
- Promotion model: import resources into staging workspace, validate, atomic promotion to production

**Challenge Addressed**: Validating migrated infrastructure across parallel environments without risking production downtime.

### Cloud Architecture Context

In modern cloud architectures, Terraform occupies a critical layer:

```
┌─────────────────────────────────────┐
│     CI/CD Pipeline (GitHub, GitLab) │
│     (Policy Enforcement)            │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Terraform Cloud/Enterprise        │
│   (Governance, Execution, State)    │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Secrets Management Layer          │
│   (Vault, SSM, KMS)                 │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│   Cloud Infrastructure Providers    │
│   (AWS, Azure, GCP)                 │
└─────────────────────────────────────┘
```

Secrets management sits at the intersection of:
- **Confidentiality**: Ensuring only authorized consumers access secret values
- **Integrity**: Detecting unauthorized modifications to secrets
- **Availability**: Providing secrets reliably to Terraform at execution time
- **Auditability**: Creating immutable records of who accessed secrets, when, and why

Multi-environment strategies ensure this layered approach scales consistently across environments with appropriate isolation and promotion workflows.

---

## Foundational Concepts

### Architecture Fundamentals

#### The Secret Lifecycle in Terraform

Senior engineers understand that managing secrets in Terraform involves six distinct phases:

1. **Secret Creation**: Where secrets originate (manually created, generated by services, rotated by external systems)
2. **Storage**: Where secrets persist at rest (encrypted backends, external vaults)
3. **Retrieval**: How Terraform accesses secrets during execution (data sources, environment injection)
4. **Usage**: How secrets are applied to infrastructure (passed to providers, embedded in resources)
5. **Exposure Minimization**: Preventing leakage to logs, state files, and outputs
6. **Rotation and Lifecycle**: Automated updates and old secret decommissioning

**The Core Challenge**: Each phase has security implications. A failure at any stage compromises the entire strategy.

#### State File Security Model

Terraform state files are the system of record for infrastructure and inherently contain sensitive data:

- **Contains**: Resource attributes set by providers (database passwords, API keys returned from AWS, TLS certificates)
- **Persistence**: State exists at rest (in backends) and in transit (during plan/apply operations)
- **Access Control**: Must be restricted to Terraform processes and authorized administrators

The principle: **Never treat state files as non-sensitive, regardless of which secrets management approach you use.**

#### The Multi-environment Complexity

Traditional configuration management treated environments identically with parameter changes. Infrastructure-as-code complicates this:

- **Compute scaling**: Environments legitimately differ in instance types, autoscaling policies
- **Redundancy levels**: Production expects multi-region failover; dev does not
- **Compliance boundaries**: Data residency requirements differ by environment
- **Cost optimization**: Dev/staging use cheaper instance types; production uses reserved capacity

Managing these differences requires strategy layers:
- Code layer: Modules supporting variation
- Variable layer: Environment-specific tfvars
- Workspace layer: Isolated state per environment
- Promotion layer: Staged progression through environments

### DevOps Principles

#### The Zero-Trust Approach to Secrets

In enterprise DevOps:
- **No implicit trust**: Just because code runs in Terraform doesn't mean it should have secret access
- **Least privilege**: Services receive only the specific secrets they need
- **Time-limited credentials**: Temporary credentials (dynamic secrets) are preferred over static
- **Audit by default**: All secret access generates logs

This principle extends to Terraform operations:
- Not all team members should access all secrets
- Not all workspaces should have credential access
- Not all plan/apply operations should execute equally

#### Immutable Infrastructure Requires Immutable Configuration

Multi-environment consistency depends on:
- **Configuration inheritance**: Base configurations inherited, not copied
- **Single source of truth**: One definition of what infrastructure should be
- **Environment variation through composition**: Changes applied consistently, variation explicit

If development and production Terraform configurations diverge gradually, they become different systems managed by the same tool—a critical failure mode.

#### Separation of Concerns

Enterprise Terraform separates:

1. **State Isolation**: Each environment has isolated backend/state
2. **Credential Isolation**: Credentials for one environment should not be visible in others
3. **Code Isolation**: Base infrastructure code is shared; environment variation is explicit
4. **Team Isolation**: Different teams manage different infrastructure with access controls
5. **Approval Workflows**: Approval chains differ by environment (dev: automatic, prod: manual)

### Best Practices Framework

#### The Defense-in-Depth Model

Single security controls are insufficient; stack them:

```
Layer 1: Backend Encryption (rest)
   ↓
Layer 2: Transport Encryption (in transit)
   ↓
Layer 3: Access Control (who can read state)
   ↓
Layer 4: Secrets Injection (avoid storing in state)
   ↓
Layer 5: Audit Logging (what was accessed)
   ↓
Layer 6: Secret Rotation (time-limited credentials)
```

Each layer is imperfect; combined, they provide comprehensive protection.

#### Configuration as Documentation

Senior DevOps practitioners write Terraform configurations that document themselves:

```hcl
variable "database_password" {
  description       = "Master password for RDS PostgreSQL (managed by Vault auto-auth)"
  type             = string
  sensitive        = true
  # Documentation about where this comes from
}

# Explicit, documentable pattern
resource "aws_db_instance" "primary" {
  password = var.database_password  # Sourced from Vault
}
```

This contrasts with implicit assumptions about where credentials come from or how they're managed.

#### Drift Detection as a Fundamental Control

In multi-environment setups:
- **Expected drift**: Intentional differences (dev has fewer replicas)
- **Unexpected drift**: Configuration divergence, external changes, state corruption

Detecting and preventing unexpected drift is critical:
- Regular `terraform plan` in VCS pipelines
- Sentinel/OPA policies preventing drift-causing changes
- Environment parity testing (same configuration should produce same infrastructure shape)

### Common Misunderstandings

#### Misunderstanding 1: Sensitive Variables = Secrets Management

Many teams believe marking variables `sensitive = true` secures secrets:

```hcl
# This is NOT secrets management
variable "api_key" {
  type      = string
  sensitive = true  # Only affects plan/apply output redaction
}
```

**Reality**: The `sensitive` flag only prevents logging the variable value in plan/apply output. The secret is still:
- Written to state file (in plaintext if state isn't encrypted)
- Visible to anyone with backend access
- Passed to providers in plaintext

**Correct approach**: Use external secret stores (Vault, SSM) and read via data sources, keeping secrets out of Terraform state entirely.

#### Misunderstanding 2: Terraform Cloud = Complete Security Solution

Terraform Cloud provides governance and centralized execution but is not sufficient alone:

```
Terraform Cloud provides:             Terraform Cloud does NOT provide:
✓ Access control to workspaces       ✗ Secret value encryption
✓ Run approval workflows              ✗ Compliance-specific controls
✓ Policy enforcement                  ✗ Dynamic credential rotation
✓ Audit logging of runs               ✗ Secrets rotation automation
```

Terraform Cloud should be **one layer** of a comprehensive strategy, not the security solution itself.

#### Misunderstanding 3: One Environment Configuration Scales to All

Early-stage teams often believe one set of Terraform code with `if/else` logic supports multiple environments:

```hcl
# Problematic approach
resource "aws_instance" "app" {
  instance_type = var.environment == "prod" ? "c5.2xlarge" : "t3.micro"
  # ... 50+ more conditional blocks
}
```

**Problems**:
- Configuration drift difficult to detect (logic scattered)
- Testing becomes complex (test every conditional)
- New environments require code changes
- Promotes configuration as-code rather than infrastructure-as-code

**Correct approach**: 
- Shared base modules with explicit variation points
- Separate variable files per environment
- Workspace isolation for state
- Environment promotion through systematic processes

#### Misunderstanding 4: Secrets Rotation Happens Automatically

Teams implementing Vault or SSM often assume rotation is automatic:

```hcl
# This reads the current secret value, but rotation requires:
# 1. Secret updated in Vault/SSM
# 2. Terraform plan/apply runs again (or drift detection triggers)
# 3. Resource updates (may require app restart)
data "aws_ssm_parameter" "db_password" {
  name = "/prod/rds/password"
}
```

**Reality**: Rotation requires:
1. Update strategy defined (blue/green, rolling, canary)
2. Consumer restart strategy (how apps reconnect with new credentials)
3. Synchronization between secret rotation and infrastructure update
4. Validation that rotation succeeded

**Correct approach**: Implement dynamic secrets (Vault) where possible, or design infrastructure to support credential rotation without downtime.

#### Misunderstanding 5: Multi-environment = Multiple Copies of Everything

Some teams maintain separate Terraform repositories for each environment:

```
❌ Anti-pattern:
infrastructure-dev/
infrastructure-staging/
infrastructure-prod/

✓ Correct pattern:
infrastructure/
  ├── modules/          (shared)
  ├── environments/
  │   ├── dev/          (tfvars only)
  │   ├── staging/      (tfvars only)
  │   └── prod/         (tfvars only)
```

Separate repositories cause:
- Configuration drift (fixes in one don't propagate)
- Testing burden (changes tested against 3 environments)
- Promotion complexity
- Maintenance overhead

**Correct approach**: Single repository with environment-specific variable files, enabling consistent promotion workflows.

---

## Terraform Secrets Management

### Principles of Secrets in Infrastructure

Before diving into specific tools, understand what makes secrets special in infrastructure-as-code:

#### Why Terraform Secrets Differ from Application Secrets

**Application-level secrecy** (password to database from app code):
- Often cached in memory
- Accessed once during startup
- Modified by application logic
- Application manages lifecycle

**Infrastructure secrecy** (credentials to create/modify infrastructure):
- Accessed repeatedly across plan/apply operations
- Embedded in state files (persistent storage)
- Modified externally (CI/CD, automation)
- Infrastructure and secrets must stay synchronized

**The core difference**: Infrastructure credentials are stored in state and must remain valid throughout the infrastructure's lifetime. A compromised database password can be changed via the application. A compromised AWS credential controlling infrastructure has no self-healing mechanism.

#### The Three Phases of Secret Handling

1. **Before Terraform Execution**
   - Where secrets are retrieved/injected
   - Critical: Avoid storing in version control, environment files, or command history

2. **During Terraform Execution**
   - How secrets are used within Terraform context
   - Critical: Prevent logging, prevent state file storage

3. **After Terraform Execution**
   - How secrets persist in state and are managed
   - Critical: Encryption at rest, access control, rotation

### Vault Integration

#### High-Level Architecture

HashiCorp Vault provides a centralized secret store with dynamic credential generation:

```
┌──────────────────────────┐
│   Terraform Cloud        │
│   (or local execution)   │
└────────────┬─────────────┘
             │
┌────────────▼──────────────────────┐
│   Vault Agent (or AppRole auth)   │
│   ├─ K/V secret retrieval         │
│   ├─ Dynamic credentials (DB)     │
│   └─ Secret rotation handling     │
└────────────┬──────────────────────┘
             │
┌────────────▼─────────────────────┐
│   Vault Server                   │
│   ├─ Secret storage (encrypted)  │
│   ├─ Access control              │
│   ├─ Audit logging               │
│   └─ Rotation policies           │
└──────────────────────────────────┘
```

#### Vault for Encrypted Secret Storage (K/V)

Static secrets stored in Vault with K/V mount:

```hcl
# Data source to retrieve secrets from Vault
data "vault_generic_secret" "aws_credentials" {
  path = "secret/data/aws/prod"
}

# Extract credentials for use
locals {
  aws_access_key = data.vault_generic_secret.aws_credentials.data["aws_access_key_id"]
  aws_secret_key = data.vault_generic_secret.aws_credentials.data["aws_secret_access_key"]
}

# Use in provider (but be aware of state implications)
provider "aws" {
  access_key = local.aws_access_key
  secret_key = local.aws_secret_key
}
```

**Critical consideration**: While Vault secures the secret in transit, the provider credential is still stored in state. This approach is appropriate when state has strong encryption and access controls.

#### Vault for Dynamic Database Credentials

Superior to static credentials, dynamic credentials:
- Generated on-demand
- Valid for limited period (TTL)
- Automatically revoked after TTL
- Audit trail of who received which credential at what time

```hcl
# Request dynamic credentials from Vault
data "vault_database_secret_backend_connection" "postgres" {
  backend       = vault_mount.database.path
  name          = "postgres-prod"
}

# Generate temporary database user
data "vault_generic_secret" "db_password" {
  path = "database/creds/terraform-role"
}

locals {
  db_username = data.vault_generic_secret.db_password.data["username"]
  db_password = data.vault_generic_secret.db_password.data["password"]
}

# Database resource uses temporary credentials
resource "aws_db_instance" "primary" {
  # ... 
  username = local.db_username
  password = local.db_password
  # Note: These are temporary and will be revoked by Vault's TTL
}
```

**Sequence**:
1. Terraform requests password credential from Vault for specific role
2. Vault generates unique username/password valid for 1 hour
3. Terraform applies changes using temporary credentials
4. State contains temporary credentials that expire
5. Vault automatically revokes the credential after TTL

#### Vault Agent Auto-Auth for Terraform Cloud

In Terraform Cloud, Vault Agent runs as a system daemon on execution workers, authenticating to Vault:

```
Terraform Cloud Worker
  │
  ├─ Vault Agent
  │  ├─ Authenticates to Vault (AppRole, JWT authentication)
  │  ├─ Retrieves secrets on request
  │  └─ Manages token lifecycle
  │
  └─ Terraform Process
     ├─ Requests secret from local Vault Agent
     ├─ Agent returns decrypted secret
     └─ Terraform uses in configuration
```

**Benefits**:
- Terraform Cloud never stores Vault credentials
- Only AppRole credentials stored in Terraform Cloud (rotatable service credentials)
- Secrets retrieved just-in-time at execution

### AWS Systems Manager Parameter Store

#### Parameter Store as Secrets Backend

AWS Systems Manager Parameter Store provides:
- **Encryption**: KMS encryption at rest (if configured)
- **Access Control**: IAM policies control who can read parameters
- **Versioning**: Historical parameter values retained
- **TTL**: No native TTL; rotation requires external process

```hcl
# Reference SSM parameter from Terraform
data "aws_ssm_parameter" "rds_password" {
  name            = "/prod/rds/master_password"
  with_decryption = true  # Decrypt KMS-encrypted values
}

# Use in configuration
resource "aws_db_instance" "primary" {
  master_password = data.aws_ssm_parameter.rds_password.value
  # ... additional configuration
}
```

#### Parameter Naming Conventions for Multi-environment

Organize parameters hierarchically for clarity:

```
/prod/rds/master_password          (production database password)
/prod/api/slack_webhook            (production Slack integration)
/staging/rds/master_password       (staging database password)
/dev/rds/master_password           (dev database password)

/prod/kms/key_id                   (KMS key references)
/prod/certificates/wildcard_cert   (TLS certificates)
```

**Advantages**:
- Clear environment separation
- Path-based access control possible
- Historical lookups straightforward

#### Parameter Store with Terraform Cloud

```hcl
# In Terraform Cloud, configure AWS credentials via environment variables
# TF_VAR_aws_region, AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, etc.

variable "environment" {
  type = string
  # Set via Terraform Cloud workspace variables
}

# Parameter retrieval uses Terraform Cloud-provided AWS credentials
data "aws_ssm_parameter" "app_secret" {
  name = "/${var.environment}/app/secret_key"
}
```

### Environment Variables

#### Sensitive Environment Variable Injection

For simple cases, environment variables provide secrets without storing in state:

```bash
# In CI/CD or Terraform Cloud environment
export TF_VAR_database_password="$(vault kv get -field=password secret/rds/prod)"

# Terraform reads via variable definition
terraform apply -var="environment=prod"
```

#### Variable Definition in Terraform

```hcl
variable "database_password" {
  description = "Database master password (from environment)"
  type        = string
  sensitive   = true
  # Don't provide default; require from environment
}

resource "aws_rds_cluster_instance" "primary" {
  identifier         = "prod-db-cluster"
  db_password        = var.database_password
  # ...
}
```

**Strength**: Secrets never written to `.tfvars` files or state (provider handles storage)

**Limitation**: If provider needs to store the secret in state, environment variables don't fully isolate secrets.

#### Terraform Cloud Environment Variables

Terraform Cloud UI allows setting environment variables marked **sensitive**:

```
Workspace: Production
Environment Variables:
  TF_VAR_db_password = ••••••••(marked sensitive)
  TF_VAR_api_key = ••••••••(marked sensitive)
  AWS_ACCESS_KEY_ID = ••••••••(marked sensitive)
```

**Advantages**:
- Centralized management
- Audit logging of access
- Can be versioned/rotated
- No local machine exposure

**Limitations**:
- Still stored in Terraform Cloud database
- Subject to Terraform Cloud access controls (less fine-grained than Vault)

### Sensitive Variables

#### The `sensitive` Attribute in Terraform

Marking a variable `sensitive = true` has specific, limited effects:

```hcl
variable "database_password" {
  type      = string
  sensitive = true
}

output "database_endpoint" {
  value     = aws_db_instance.primary.endpoint
  sensitive = false  # Safe to expose in logs
}

output "database_master_user" {
  value     = aws_db_instance.primary.master_username
  sensitive = true  # Could link to password; hide from logs
}
```

**What `sensitive` Does**:
- Redacts value from `terraform plan` output
- Redacts from `terraform apply` output
- Redacts from `terraform output` command
- Prevents accidental logging in logs/CI systems

**What `sensitive` Does NOT Do**:
- Encrypt the value in state files
- Restrict who can read state
- Prevent state inspection via state inspection tools
- Encrypt values in memory during Terraform execution

**Correct use**: `sensitive = true` is a **display/logging control**, not a security control. Use in combination with other controls (state encryption, access control, secrets management).

#### Sensitive Outputs in Multi-environment

```hcl
# In each environment's tfvars, mark password variable sensitive
variable "rds_master_password" {
  type      = string
  sensitive = true
  description = "Retrieved from Vault via environment variable"
}

# Output endpoints for team reference, but not sensitive
output "database_endpoint" {
  value       = aws_db_instance.primary.address
  description = "Primary database endpoint for application configuration"
}

# Output secrets required by other tiers, mark as sensitive
output "database_password" {
  value       = var.rds_master_password
  sensitive   = true
  description = "Password passed to application tier (DO NOT LOG)"
}
```

### Secure Backends

#### Backend Encryption Overview

Terraform stores state in backends (local disk, S3, Terraform Cloud, Consul, etc.). Backends have different encryption characteristics:

| Backend | Rest Encryption | In-Transit | Access Control | Locking |
|---------|-----------------|-----------|-----------------|---------|
| Local   | None (default)  | N/A       | File system ACL | File   |
| S3      | KMS configurable| TLS       | IAM policies    | DynamoDB |
| Azure   | Configurable    | TLS       | Azure RBAC      | Blob   |
| Terraform Cloud | AES-256 | TLS | IAM + workspace controls | Native |
| Consul  | TLS encryption  | TLS       | ACLs            | Native |

#### S3 Backend with Encryption

```hcl
# Backend configuration with encryption
terraform {
  backend "s3" {
    bucket         = "terraform-state-prod"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true              # Enable server-side encryption
    dynamodb_table = "terraform-locks" # State locking
    
    # Enforce encryption via bucket policy (even if missed here)
  }
}

# Separate backend configs per environment
# backend/prod.hcl:
bucket         = "terraform-state-prod"
dynamodb_table = "terraform-locks-prod"
```

#### S3 Bucket Policy for Encryption Enforcement

```hcl
resource "aws_s3_bucket_policy" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = "aws:kms"
          }
        }
      },
      {
        Effect = "Deny"
        Principal = "*"
        Action = "s3:PutObject"
        Resource = "${aws_s3_bucket.terraform_state.arn}/*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption-aws-kms-key-arn" = aws_kms_key.terraform.arn
          }
        }
      }
    ]
  })
}
```

#### Remote Backends and Workspace Isolation

In multi-environment setups, separate backends ensure state isolation:

```hcl
# Development environment backend
terraform {
  backend "s3" {
    bucket = "terraform-state-dev"
    key    = "infrastructure/terraform.tfstate"
    region = "us-east-1"
    encrypt = true
  }
}

# Production environment backend (completely separate)
# Requires running: terraform init -backend-config=backend/prod.hcl
terraform {
  backend "s3" {
    # placeholder - overridden by -backend-config
  }
}

# backend/prod.hcl
bucket         = "terraform-state-prod"
key            = "infrastructure/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
dynamodb_table = "terraform-locks-prod"
```

#### Terraform Cloud as Remote Backend

```hcl
terraform {
  cloud {
    organization = "my-company"
    
    workspaces {
      name = "production"  # Workspace-specific state
    }
  }

  # All state stored in Terraform Cloud infrastructure
  # Encrypted with AES-256
  # Access controlled via organization/team/workspace permissions
}
```

**Benefits over S3**:
- Managed encryption (no configuration needed)
- Built-in state locking
- Cost control (prevents runaway infrastructure)
- Audit logging of who accessed state when
- Integrated policy enforcement

---

## Terraform Cloud/Enterprise

### Workspace Management

#### Workspace as State Container

Each Terraform Cloud workspace maintains:
- Independent state file
- Separate variable values
- Distinct run history
- Individual lock state

```
Terraform Cloud Organization
├── Project: Infrastructure
│   ├── Workspace: dev
│   │   ├── State: dev-terraform.tfstate
│   │   ├── Variables: TF_VAR_instance_type = t3.micro
│   │   └── Runs: (execution history)
│   ├── Workspace: staging
│   │   ├── State: staging-terraform.tfstate
│   │   └── Variables: TF_VAR_instance_type = t3.small
│   └── Workspace: production
│       ├── State: prod-terraform.tfstate
│       └── Variables: TF_VAR_instance_type = c5.2xlarge
└── Project: Networking
```

#### Workspace Naming Strategy

Recommended pattern for multi-environment organization:

```
{application}-{environment}        # application-prod
{team}-{service}-{environment}     # platform-gateway-prod
{region}-{purpose}                 # us-east-1-networking

Examples:
- auth-service-production
- data-pipeline-staging
- network-infrastructure-prod
- ci-runner-fleet-dev
```

#### Workspace-Specific Variables

Variables can be set per workspace in Terraform Cloud:

```
Workspace: auth-service-production
Variables:
  TF_VAR_instance_count = 5
  TF_VAR_instance_type = c5.xlarge
  TF_VAR_multi_az = true
  AWS_REGION = us-east-1
  
Workspace: auth-service-staging
Variables:
  TF_VAR_instance_count = 2
  TF_VAR_instance_type = t3.large
  TF_VAR_multi_az = false
  AWS_REGION = us-west-2
```

#### State Isolation by Workspace

Each workspace maintains completely separate state:

```
❌ Problem without workspace isolation:
resource "aws_instance" "app" {
  for_each = local.all_instances  # Includes dev + prod
  # ... configuration
}

✓ Solution with workspace isolation:
# dev workspace uses: local.instances = var.dev_instances
# prod workspace uses: local.instances = var.prod_instances
```

### Remote Execution

#### VCS Integration for Plan/Apply

Terraform Cloud integrates with Git repositories for automated workflows:

```
Developer Push to GitHub
    │
    ├─ Webhook → Terraform Cloud
    │
    ├─ Terraform Cloud checks out repository
    │
    ├─ Runs: terraform plan
    │
    ├─ Plan output in PR comment
    │
    └─ Approval workflow:
       ├─ PR approved in GitHub
       ├─ Merged to main
       ├─ Webhook triggers apply
       └─ terraform apply executes automatically
```

**VCS Configuration**:
```hcl
# terraform {
#   cloud {
#     organization = "my-company"
#     workspaces {
#       name = "production"
#     }
#   }
# }
# 
# Terraform Cloud UI:
# ├─ VCS Provider: GitHub
# ├─ Repository: org/infrastructure
# ├─ Branch: main
# └─ Terraform Working Directory: infrastructure/
```

#### Speculative Plans (Dry-Run)

Before merging to main, run plans against the actual state:

```bash
# In feature branch
terraform login  # Authenticate to Terraform Cloud
terraform plan

# Output:
# Initializing Terraform Cloud backend...
# Running plan in Terraform Cloud...
# 
# Plan: 2 to add, 1 to modify, 0 to destroy
# 
# Plan available at:
# https://app.terraform.io/app/my-company/workspaces/prod/runs/run-xyz
```

Developers can review the speculative plan before requesting approval, catching configuration issues early.

#### Remote Execution Benefits

1. **Consistent Execution Environment**
   - All plans/applies run against same Terraform version
   - No local environment drift
   - Predictable behavior

2. **Audit Trail**
   - Who triggered the run
   - What changes were made
   - When approval occurred
   - Apply execution details

3. **Secrets Isolation**
   - Terraform Cloud stores secrets centrally
   - Local machines never see credential values
   - Reduces attack surface

### Policy as Code

#### Sentinel Policies for Governance

Sentinel policies are rules that govern allowed infrastructure changes. They run after `terraform plan` and block applies that violate policies.

```
┌─────────────────────────────┐
│ terraform plan output       │
└────────────┬────────────────┘
             │ (plan.json)
┌────────────▼────────────────┐
│  Sentinel Policy Engine     │
│  ├─ Check tag policy        │
│  ├─ Check cost policy       │
│  ├─ Check encryption policy │
│  └─ Check resource policy   │
└────────────┬────────────────┘
             │
        Pass? 
        / \
       /   \
      yes   no (block apply)
     /       \
Proceed to  Return to developer
Approval    with violations
```

#### Example: Tag Enforcement Policy

```hcl
# policies/require-tags.sentinel
import "tfplan/v2" as tfplan

// Allowed resource types to enforce tags on
allowed_types = ["aws_instance", "aws_db_instance", "aws_s3_bucket"]

// Allowed tags
required_tags = ["Environment", "Owner", "CostCenter"]

violations = []

for resource_type in allowed_types {
  for resource in tfplan.resources.aws_instance {
    for instance_name, instance in resource {
      // Check if resource has required tags
      if instance.change.after.tags is empty {
        append(violations, {
          resource = resource_type + "." + instance_name,
          message = "Resource must have tags: " + join(", ", required_tags)
        })
      } else {
        for required_tag in required_tags {
          if instance.change.after.tags is not empty and
             required_tag not in instance.change.after.tags {
            append(violations, {
              resource = resource_type + "." + instance_name,
              message = "Missing required tag: " + required_tag
            })
          }
        }
      }
    }
  }
}

main = length(violations) == 0
```

**Enforcement**: Policies blocks applies until violations are resolved.

#### Example: Cost Control Policy

```hcl
# policies/cost-limit.sentinel
import "tfplan/v2" as tfplan
import "decimal" as decimal

// Cost estimates per resource type (monthly)
cost_map = {
  "aws_instance": {
    "t3.micro": decimal.new("10"),
    "t3.small": decimal.new("20"),
    "m5.large": decimal.new("80"),
    "c5.2xlarge": decimal.new("500"),
  },
  "aws_rds_instance": {
    "db.t3.micro": decimal.new("50"),
    "db.r5.2xlarge": decimal.new("2000"),
  }
}

// Environment cost limits
env_limits = {
  "dev": decimal.new("500"),
  "staging": decimal.new("2000"),
  "prod": decimal.new("50000"),
}

environment = tfplan.variables.environment.value
limit = env_limits[environment]
total_cost = decimal.new("0")

for resource_type, resources in tfplan.resources {
  for resource_name, resource_list in resources {
    for resource_instance_name, resource_instance in resource_list {
      if resource_type in cost_map {
        instance_type = resource_instance.change.after.instance_type
        if instance_type in cost_map[resource_type] {
          cost = cost_map[resource_type][instance_type]
          total_cost = total_cost.add(cost)
        }
      }
    }
  }
}

main = total_cost.less_than_or_equal_to(limit)
```

This policy prevents provisioning infrastructure exceeding the environment's cost limit.

#### Policy as Code vs. Approval Workflows

**Policies (Sentinel)**:
- Automatic enforcement
- Consistent validation across all users
- Prevents violations from occurring

**Approval Workflows**:
- Manual decision-making
- Flexibility for exceptions
- Requires human judgment

**Best practice**: Combine both—use policies for non-negotiable rules (encryption, tags, security), approval workflows for discretionary decisions (cost, timing).

### Run Workflows

#### Standard Run Workflow

```
1. VCS Trigger
   └─ Developer pushes to repository

2. Plan Queue
   └─ Workspace queues terraform plan

3. Queued State
   └─ Terraform Cloud prepares plan

4. Planning
   └─ terraform plan executes
   └─ Resource changes calculated
   └─ Output stored in run.json

5. Planned State
   └─ Plan available for review
   └─ Runs policies against plan
   └─ Reports policy failures if any

6. Policy Check (if configured)
   └─ Sentinel policies validate plan
   └─ Violations prevent progression

7. Pending Approval
   └─ Requires manual approval
   └─ Authorized user reviews changes

8. Confirmed
   └─ User approves the run

9. Applying
   └─ terraform apply executes
   └─ Infrastructure changes applied

10. Applied/Done
    └─ Run completes successfully
    └─ State file updated
    └─ Run logged in history
```

#### Automatic Applies for Low-Risk Changes

For development environments, configured workspaces can auto-apply:

```hcl
# Terraform Cloud Workspace Settings
Auto Apply: Enabled
Execution Mode: Remote/API-Driven
```

**Configuration**:
```
Workspace: dev-infrastructure
├─ Auto Apply: Enabled
├─ Requires approval: No
└─ Runs automatically after plan succeeds

Workspace: prod-infrastructure
├─ Auto Apply: Disabled
├─ Requires approval: Yes
└─ Manual approval required
```

#### Run State and Outputs

Each run generates outputs useful for downstream processes:

```
Run ID: run-abc123
Status: Applied
Created: 2024-03-15 10:30:00 UTC
User: alice@company.com

Outputs:
├─ database_endpoint: db.example.com
├─ load_balancer_dns: nlb-12345.elb.amazonaws.com
└─ cluster_name: prod-k8s-001

Changes Summary:
├─ Resources added: 5
├─ Resources changed: 2
├─ Resources destroyed: 0
└─ Log: Available
```

External processes can query Terraform Cloud API for run details:

```bash
curl -s -H "Authorization: Bearer $TFC_TOKEN" \
  https://app.terraform.io/api/v2/organizations/my-company/runs/run-abc123 \
  | jq '.data.attributes.status'
```

### Collaboration Features

#### Team-Based Access Control

Terraform Cloud allows fine-grained access within organizations:

```
Organization: my-company

Teams:
├─ Platform (infrastructure team)
│  ├─ Members: alice, bob
│  └─ Permissions:
│     ├─ All workspaces: Admin
│     └─ State Management: Full
│
├─ Data (data engineering team)
│  ├─ Members: charlie
│  └─ Permissions:
│     ├─ data-* workspaces: Write
│     ├─ Other workspaces: Read
│     └─ State Management: Limited
│
└─ Security (security team)
   ├─ Members: david
   └─ Permissions:
      ├─ All workspaces: Read-only
      └─ Audit logging: Read
```

#### Run Comments and Collaboration

Terraform Cloud integrates with Git for collaborative review:

```
GitHub PR:
├─ Comment from Terraform Cloud (automatic):
│  ├─ terraform plan output
│  ├─ Environment impact
│  ├─ Cost estimate
│  └─ Policy check status
│
├─ Team members comment
│  ├─ Review infrastructure changes
│  ├─ Request modifications
│  └─ Approve/reject
│
└─ Notification to author
   ├─ Policy violations found
   ├─ Cost exceeded
   ├─ Or: Ready for approval
```

#### Cost Estimation

Terraform Cloud estimates monthly cost for infrastructure changes:

```bash
# terraform plan output (in VCS PR comment):
Terraform will perform the following actions:

  # aws_instance.app[0] will be created
  + resource "aws_instance" "app" {
      ami = "ami-0c55b159cbfafe1f0"
      ...
      instance_type = "m5.large"
    }

Cost estimate:
  Prior monthly cost: $500
  Proposed monthly cost: $750
  Monthly cost delta: +$250
```

Useful for catching unexpected cost increases from infrastructure changes.

#### VCS Integration and Notifications

```
GitHub / GitLab / Bitbucket
    │
    ├─ Webhook on push
    │
    ├─ Terraform Cloud receives event
    │
    ├─ Checks VCS branch & directory
    │
    ├─ Triggers terraform plan
    │
    ├─ Posts plan results to PR comment
    │
    ├─ PR approval in VCS
    │
    ├─ Webhook on merge
    │
    ├─ Terraform Cloud triggers apply
    │
    └─ Results posted to commit comment
```

---

## Multi-environment Strategies

### Workspace Strategies

#### Strategy 1: Environment Per Workspace

Each environment (dev, staging, prod) is a separate workspace with distinct state:

**Directory Structure**:
```
infrastructure/
├── main.tf (shared configuration)
├── variables.tf (shared variable definitions)
├── outputs.tf (shared output definitions)
│
├── terraform.tfvars (committed - non-sensitive defaults)
├── terraform.tfvars.json (non-sensitive baseline)
│
└── environments/
    ├── dev.tfvars
    ├── staging.tfvars
    └── prod.tfvars
```

**Terraform Cloud Configuration**:
```
Workspaces:
├─ infrastructure-dev
│  ├─ Working directory: infrastructure/
│  ├─ Backend config: dev.tfvars
│  └─ State: separate
│
├─ infrastructure-staging
│  ├─ Working directory: infrastructure/
│  ├─ Backend config: staging.tfvars
│  └─ State: separate
│
└─ infrastructure-prod
   ├─ Working directory: infrastructure/
   ├─ Backend config: prod.tfvars
   └─ State: separate
```

**Advantages**:
- Complete state isolation
- Different apply approval requirements per environment
- Clear environment boundaries
- Testing in dev doesn't affect prod

**Disadvantages**:
- Single code base must handle all variations
- Testing increases with environment count
- Variable management complexity

#### Strategy 2: Service Per Workspace

Organize workspaces by service/component rather than environment:

```
Workspaces:
├─ networking-prod
├─ networking-staging
├─ networking-dev
│
├─ database-prod
├─ database-staging
├─ database-dev
│
├─ kubernetes-prod
├─ kubernetes-staging
└─ kubernetes-dev
```

**Advantages**:
- Teams own specific services with all environments
- Clear ownership and RBAC
- Easier to test service changes across environments

**Disadvantages**:
- Workspaces become numerous quickly
- Cross-service dependencies harder to manage
- Promotion workflow more complex

#### Strategy 3: Account/Region Per Workspace

For multi-account AWS/Azure strategies:

```
Workspaces (AWS):
├─ sandbox-account-east
├─ dev-account-east
├─ dev-account-west
│
├─ staging-account-east
├─ staging-account-west (multi-region)
│
├─ prod-account-primary-east
├─ prod-account-primary-west (active-active)
├─ prod-account-dr-central
└─ prod-account-dr-backup
```

**Advantages**:
- Workspaces align with cloud account structure
- Natural disaster recovery boundaries
- Compliance/isolation requirements met

**Disadvantages**:
- Many workspaces to manage
- Testing all account combinations expensive
- Promotion workflows complex

#### Recommended Hybrid Approach

Combine strategies based on scale:

```
Small Organizations (< 5 teams):
Infrastructure/
├─ main.tf
├─ environments/
│  ├─ dev.tfvars
│  ├─ staging.tfvars
│  └─ prod.tfvars

Workspaces (Terraform Cloud):
├─ infrastructure-dev
├─ infrastructure-staging
└─ infrastructure-prod
```

```
Medium Organizations (5-20 teams):
Infrastructure/
├─ modules/
│  ├─ networking/
│  ├─ database/
│  └─ kubernetes/
├─ environments/
│  ├─ dev.tfvars
│  ├─ staging.tfvars
│  └─ prod.tfvars

Workspaces (Terraform Cloud):
├─ base-networking-prod
├─ base-database-prod
├─ app-service-a-prod
├─ app-service-b-prod
```

### Directory Structure Patterns

#### Pattern 1: Monolithic Repository with Environments

```
infrastructure/
├─ README.md
├─ provider.tf                    (provider config)
├─ variables.tf                   (variable definitions)
├─ outputs.tf                     (output definitions)
├─ main.tf                        (main resources)
├─ vpc.tf                         (VPC-specific)
├─ database.tf                    (database-specific)
├─ kubernetes.tf                  (K8s-specific)
│
├─ environments/
│  ├─ dev.tfvars                  (dev-specific values)
│  ├─ staging.tfvars              (staging-specific values)
│  └─ prod.tfvars                 (prod-specific values)
│
├─ modules/
│  ├─ security_group/
│  ├─ rds_cluster/
│  └─ eks_cluster/
│
├─ terraform.tfvars               (default/committable)
└─ backend/
   ├─ dev.hcl                     (dev backend config)
   ├─ staging.hcl
   └─ prod.hcl
```

**Execution**:
```bash
# Development
terraform init -backend-config=backend/dev.hcl
terraform plan -var-file=environments/dev.tfvars

# Production
terraform init -backend-config=backend/prod.hcl
terraform plan -var-file=environments/prod.tfvars
```

**Advantages**: Simplicity, single code base, easy testing

**Disadvantages**: All environments in one state (risk of accidental changes), variable explosion

#### Pattern 2: Layered/Modular Repository

Separate infrastructure into logical layers with modules:

```
infrastructure/
├─ modules/
│  ├─ base/                       (VPC, subnets, routing)
│  │  ├─ main.tf
│  │  ├─ variables.tf
│  │  └─ outputs.tf
│  │
│  ├─ application/                (APP servers)
│  │  ├─ main.tf
│  │  ├─ variables.tf
│  │  └─ outputs.tf
│  │
│  └─ persistence/                (database, caching)
│     ├─ main.tf
│     ├─ variables.tf
│     └─ outputs.tf
│
├─ environments/
│  ├─ dev/
│  │  ├─ main.tf                  (calls modules)
│  │  ├─ variables.tf
│  │  ├─ terraform.tfvars
│  │  └─ backend.hcl
│  │
│  ├─ staging/
│  │  ├─ main.tf
│  │  ├─ variables.tf
│  │  ├─ terraform.tfvars
│  │  └─ backend.hcl
│  │
│  └─ prod/
│     ├─ main.tf
│     ├─ variables.tf
│     ├─ terraform.tfvars
│     └─ backend.hcl
```

**Each environment's main.tf**:
```hcl
# environments/prod/main.tf
module "base" {
  source = "../../modules/base"
  
  vpc_cidr              = var.vpc_cidr
  availability_zones    = var.availability_zones
  enable_nat_gateway    = var.enable_nat_gateway
}

module "application" {
  source = "../../modules/application"
  
  vpc_id                = module.base.vpc_id
  instance_count        = var.instance_count
  instance_type         = var.instance_type
}

module "persistence" {
  source = "../../modules/persistence"
  
  vpc_id                = module.base.vpc_id
  subnet_ids            = module.base.subnet_ids
  database_size         = var.database_size
}
```

**Execution**:
```bash
cd environments/prod/
terraform init -backend-config=backend.hcl
terraform plan -var-file=terraform.tfvars
```

**Advantages**: Reusability, clear separation, testable modules

**Disadvantages**: More directories, complexity increases

#### Pattern 3: Repository Per Service/Team

Large organizations may partition by service:

```
organization/
├─ infrastructure-platform/
│  ├─ modules/
│  │  ├─ vpc/
│  │  ├─ subnets/
│  │  └─ vpn/
│  └─ environments/
│     ├─ dev/
│     ├─ staging/
│     └─ prod/
│
├─ infrastructure-databases/
│  ├─ modules/
│  │  ├─ rds/
│  │  ├─ redis/
│  │  └─ backup/
│  └─ environments/
│     ├─ dev/
│     ├─ staging/
│     └─ prod/
│
└─ infrastructure-kubernetes/
   ├─ modules/
   │  ├─ eks/
   │  ├─ ingress/
   │  └─ hpa/
   └─ environments/
      ├─ dev/
      ├─ staging/
      └─ prod/
```

**Advantages**: Team ownership, independent deployment, clear responsibilities

**Disadvantages**: Cross-service dependencies, multiple repositories to manage, version coordination

### Variable Management Across Environments

#### Variable Definition Strategy

Separate **definition** from **value**:

```hcl
# variables.tf (shared across all environments)
variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  # No default - value must come from tfvars or environment variable
}

variable "instance_count" {
  description = "Number of instances"
  type        = number
  default     = 1  # Can have default for optional variables
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default     = {}
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

#### Environment-Specific Values

```hcl
# environments/dev.tfvars
instance_type  = "t3.micro"
instance_count = 1
environment    = "dev"

tags = {
  Environment = "Development"
  Owner       = "DevOps"
  CostCenter  = "R&D"
}

# environments/staging.tfvars
instance_type  = "t3.medium"
instance_count = 2
environment    = "staging"

tags = {
  Environment = "Staging"
  Owner       = "QA"
  CostCenter  = "QA"
}

# environments/prod.tfvars
instance_type  = "c5.large"
instance_count = 5
environment    = "prod"

tags = {
  Environment = "Production"
  Owner       = "Platform"
  CostCenter  = "Operations"
}
```

**Execution**:
```bash
# For any environment, same command structure:
terraform plan -var-file=environments/prod.tfvars
```

#### Secrets in Multi-environment

Separate sensitive and non-sensitive variables:

```hcl
# terraform.tfvars (committable, non-sensitive)
instance_type = "t3.medium"
disk_size     = 100
enable_logging = true

# Sensitive values sourced separately:
# 1. Via Terraform Cloud workspace variables (marked sensitive)
# 2. Via environment variables (TF_VAR_* prefix)
# 3. Via Vault data sources

# variables.tf
variable "database_password" {
  type      = string
  sensitive = true
  # Sourced from external secret store, not in tfvars
}

variable "api_key" {
  type      = string
  sensitive = true
  # Sourced from Terraform Cloud variable
}

# Retrieve from vault
data "vault_generic_secret" "db_password" {
  path = "secret/data/rds/${var.environment}"
}
```

#### Variable Composition Pattern

For complex configurations, build variables from simpler parts:

```hcl
# variables.tf
variable "environment" {
  type = string
}

variable "instance_type_by_env" {
  type = map(string)
  default = {
    dev     = "t3.micro"
    staging = "t3.medium"
    prod    = "c5.2xlarge"
  }
}

variable "instance_count_by_env" {
  type = map(number)
  default = {
    dev     = 1
    staging = 2
    prod    = 5
  }
}

# main.tf
locals {
  instance_type  = var.instance_type_by_env[var.environment]
  instance_count = var.instance_count_by_env[var.environment]
}

resource "aws_instance" "app" {
  count         = local.instance_count
  instance_type = local.instance_type
  # ...
}

# environments/prod.tfvars
environment = "prod"  # Drives composition logic
```

**Benefit**: Single value (environment name) drives multiple derived values consistently.

### Promotion Models

#### Model 1: Manual Approval by Environment

Infrastructure changes progress through environments with manual approval at each step:

```
Developer    Staging        Production
   │            │              │
   │ Plan        │              │
   │────────────>│              │
   │            Apply           │
   │            (automatic)     │
   │             ├─ Verify      │
   │             ├─ Test        │
   │             │──────────────>│  Manual
   │             │              │Approval
   │             │              │  Required
   │             │              │
   │             │              │Apply
   │             │              │(on approval)
   │             │              │
   └─ Deploy Application ──────────────────>│
```

**Terraform Cloud Configuration**:
```
Workspace: app-staging
├─ Auto Apply: Enabled
├─ Requires Approval: No
└─ Runs auto-apply after plan succeeds

Workspace: app-production
├─ Auto Apply: Disabled
├─ Requires Approval: Yes
└─ Manual approval required from security team
```

**Advantages**: 
- Control over production changes
- Time for validation in lower environments
- Clear approval trail

**Disadvantages**:
- Slower change velocity
- Approval bottleneck
- Requires operational overhead

#### Model 2: Automated Promotion with Policy Guardrails

Infrastructure automatically progresses once policies pass:

```
Developer Plan
   │
   ├─ Sentinel Policies Pass? ──No──> Blocker (fail)
   │                                    
   Yes
   │
   ├─ Cost estimation OK?  ──No──> Manual review
   │
   Yes
   │
   ├─ Apply to Staging (automatic)
   │
   ├─ Run integration tests
   │
   ├─ Tests pass?  ──No──> Stop (debug)
   │
   Yes
   │
   ├─ Manual promotion gate
   │
   └─ Apply to Production
```

**Implementation**:
```hcl
# sentinel/cost-limit.sentinel
# Blocks expensive changes
main = total_cost < environment_limit

# sentinel/tags-required.sentinel
# Blocks untagged resources
main = all_resources_tagged

# sentinel/approved-regions.sentinel
# Prevents deployment to unapproved regions
main = resources_in_allowed_regions
```

**Advantages**:
- Fast, policy-driven progression
- No unnecessary manual approvals
- Clear failure reasons

**Disadvantages**:
- Policies must be comprehensive
- Difficult to override policies (by design)

#### Model 3: Canary Deployment

Roll out changes to subset of infrastructure before full deployment:

```
Dev Environment (all resources)
      ↓ (validated configuration)
Prod - Canary (5% of production traffic)
      ↓ (monitor metrics)
Prod - Blue-Green (50% gradual rollout)
      ↓ (health checks pass)
Prod - All Instances (100% deployment)
      ↓ (rollback if issues detected)
Permanent Deployment
```

**Terraform implementation**:
```hcl
# variables.tf
variable "deployment_stage" {
  type = string
  default = "full"
  validation {
    condition     = contains(["canary", "blue-green", "full"], var.deployment_stage)
    error_message = "Must be canary, blue-green, or full"
  }
}

# main.tf - canary deployment
locals {
  instance_count = {
    canary      = 1
    blue-green  = 5
    full        = 20
  }
  
  target_count = local.instance_count[var.deployment_stage]
}

resource "aws_instance" "app" {
  count         = local.target_count
  instance_type = var.instance_type
  # ...
  
  tags = {
    DeploymentStage = var.deployment_stage
    Version        = var.application_version
  }
}

# Release progression:
# environments/prod-canary.tfvars
deployment_stage = "canary"
application_version = "v1.2.3"

# environments/prod-blue-green.tfvars
deployment_stage = "blue-green"
application_version = "v1.2.3"

# environments/prod-full.tfvars
deployment_stage = "full"
application_version = "v1.2.3"
```

**Advantages**:
- Risk minimization
- Real-world validation before full rollout
- Easy rollback

#### Model 4: Blue-Green Infrastructure Switch

Maintain two complete, identical environments and switch traffic:

```
Blue Environment     Green Environment
(Current)            (New)
   │                    │
   ├─ Running prod  ├─ Built/tested
   │   infrastructure   │ from new code
   │                    │
   │                    └─ Ready for traffic
   │
   └─ Health check OK?
      │
      ├─ Yes: Switch DNS/LB to Green
      │       Swap role to Green=Current, Blue=BU
      │
      └─ No: Remediate, rebuild Green
```

**Terraform implementation**:
```hcl
# variables.tf
variable "active_environment" {
  type = string
  default = "blue"
  validation {
    condition     = contains(["blue", "green"], var.active_environment)
    error_message = "Must be blue or green"
  }
}

# main.tf
resource "aws_instance" "app_blue" {
  count         = var.active_environment == "blue" ? var.instance_count : 0
  instance_type = var.instance_type
  tags = {
    Environment = "Blue"
  }
}

resource "aws_instance" "app_green" {
  count         = var.active_environment == "green" ? var.instance_count : 0
  instance_type = var.instance_type
  tags = {
    Environment = "Green"
  }
}

# Route53 alias points to active environment's load balancer
resource "aws_route53_record" "app" {
  zone_id = aws_route53_zone.main.zone_id
  name    = "app.example.com"
  type    = "A"
  
  alias {
    name                   = var.active_environment == "blue" ? aws_lb.blue.dns_name : aws_lb.green.dns_name
    zone_id               = aws_lb.blue.zone_id
    evaluate_target_health = true
  }
}

# Promotion:
# 1. Build and test Green environment (active_environment = green in workspace)
# 2. Verify Green health
# 3. Switch DNS: Update active_environment = "blue" (keeping Green running)
# 4. Monitor
# 5. Decomission Blue after successful validation
```

**Advantages**:
- Zero-downtime deployments
- Instant rollback (switch DNS back)
- Full infrastructure validation before traffic

**Disadvantages**:
- Double infrastructure cost during transition
- State management complexity
- Requires careful DNS/LB switchover

### Best Practices

#### Best Practice 1: Environment Parity

Keep environments as identical as possible; differences should be minimal and intentional:

```hcl
# ✓ Good: Intentional difference
instance_type = {
  dev  = "t3.micro"    # Cost optimization
  prod = "c5.2xlarge"  # Performance
}

# ❌ Bad: Unintentional divergence
if var.environment == "prod" {
  # Enable feature in prod only
  # This creates version skew
}
```

**Strategy**:
- Base configuration identical in all environments
- Vary only necessary attributes (size, count, redundancy)
- Apply same modules, policies, and testing

#### Best Practice 2: Immutable Values, Mutable Configuration

Infrastructure should be immutable; configuration should be versionable:

```hcl
# ❌ Bad: Magic values embedded
resource "aws_instance" "app" {
  agent = "12345"  # What is this?
}

# ✓ Good: Explicit variable reference
variable "agent_version" {
  description = "Version of monitoring agent"
  type        = string
}

resource "aws_instance" "app" {
  user_data = "#!/bin/bash\ninstall-agent ${var.agent_version}"
}
```

Configuration should be stored in version control; values version-controlled separately (tfvars files).

#### Best Practice 3: Test Promotion, Not Just Code

Test the promotion workflow itself:

```bash
# Test promotion from staging to production
# 1. Make change in dev
terraform apply -var-file=environments/dev.tfvars

# 2. Plan in staging with same code
terraform plan -var-file=environments/staging.tfvars -out=staging.plan

# 3. Plan in prod with same code
terraform plan -var-file=environments/prod.tfvars -out=prod.plan

# 4. Verify same resource changes logic (different counts is OK)
diff staging.plan prod.plan  # Should differ only in values, not logic

# 5. Apply in order: dev → staging → prod
terraform apply dev.plan
terraform apply staging.plan
terraform apply prod.plan
```

Testing validates:
- Configuration works across environments
- Promotion process is well-defined
- Changes behave as expected at each level

#### Best Practice 4: Secrets Rotation Without Downtime

Plan infrastructure to support credential rotation:

```hcl
# For database credentials:
# 1. Vault generates new password
# 2. RDS parameter updated via Terraform
# 3. Application receives new password from AWS Secrets Manager/Vault
# 4. Application restarts (with new credentials)
# 5. Old credentials revoked

# Design infrastructure for rolling restarts
resource "aws_ecs_service" "app" {
  name            = "app"
  desired_count   = 3
  
  deployment_configuration {
    maximum_percent         = 200  # Allow 200% during rolling update
    minimum_healthy_percent = 50   # Keep 50% running
  }
}

# When password updates: ECS gracefully restarts containers
# → New containers receive new password
# → Old containers terminated
# → No downtime
```

#### Best Practice 5: Audit Trail and Change Visibility

Ensure infrastructure changes are traced end-to-end:

```
Change Source        Who                When              State
└─ Git commit        Developer         2024-03-15 10:30  v1.2.3
   ├─ Webhook        (Automatic)       2024-03-15 10:31  Queued
   └─ VCS PR         Peer reviewer     2024-03-15 10:35  Approved
      ├─ Plan        Terraform Cloud   2024-03-15 10:36  Planned
      ├─ Policy      Sentinel          2024-03-15 10:37  Passed
      └─ Apply       Terraform Cloud   2024-03-15 10:38  Applied

Audit trail available:
├─ Git: Who changed what code
├─ VCS: Who approved change
├─ Terraform Cloud: What resources changed
├─ AWS CloudTrail: What API calls executed
└─ Vault logs: What secrets were accessed
```

**Enable all logging**:
```hcl
# Terraform Cloud: Automatic
# AWS CloudTrail: Enable via Terraform
resource "aws_cloudtrail" "main" {
  s3_bucket_name           = aws_s3_bucket.cloudtrail.id
  include_global_events    = true
  is_multi_region_trail    = true
  enable_log_file_validation = true
}

# Vault: Enable audit logging
# AWS CloudWatch: Monitor all changes
```

---

## Hands-on Scenarios
*(These will be included in a supplementary section)*

---

## Interview Questions
*(These will be included in a supplementary section)*

---

**Document Version**: 1.0  
**Last Updated**: March 2024  
**Audience Level**: Senior DevOps Engineers (5-10+ years)

*Note: This guide is structured for modular expansion. Sections 6 (Hands-on Scenarios) and 7 (Interview Questions) can be merged with later documentation.*
