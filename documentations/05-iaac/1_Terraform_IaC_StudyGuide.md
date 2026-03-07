# Terraform IaC: Senior DevOps Study Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
   - [Architecture Fundamentals](#architecture-fundamentals)
   - [DevOps Principles](#devops-principles)
   - [Best Practices](#best-practices)
   - [Common Misunderstandings](#common-misunderstandings)
3. [Subtopic: Declarative vs Imperative Approaches](#subtopic-declarative-vs-imperative-approaches)
4. [Subtopic: Idempotency in IaC](#subtopic-idempotency-in-iac)
5. [Subtopic: Drift](#subtopic-drift)
6. [Subtopic: Provisioning vs Configuration Management](#subtopic-provisioning-vs-configuration-management)
7. [Hands-on Scenarios](#hands-on-scenarios)
8. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

Terraform is a declarative Infrastructure as Code (IaC) tool that enables DevOps engineers to define, provision, and manage cloud infrastructure through code. Developed by HashiCorp, Terraform abstracts the complexity of multi-cloud deployments, allowing teams to treat infrastructure with the same rigor and version control practices applied to application code.

At the enterprise level, Terraform serves as the foundation for infrastructure automation, enabling:

- **Infrastructure Versioning**: Track infrastructure changes through Git commits
- **Reproducibility**: Consistently recreate environments across development, staging, and production
- **Multi-cloud Deployment**: Uniform infrastructure definition across AWS, Azure, GCP, and on-premises resources
- **Team Collaboration**: Share infrastructure definitions while maintaining audit trails and approval workflows
- **Cost Optimization**: Identify unused resources and manage cloud spending through code reviews

### Real-world Production Use Cases

#### 1. **Multi-Region Disaster Recovery Architecture**
Organizations use Terraform to define active-passive or active-active deployments across AWS regions. Infrastructure changes in primary regions automatically propagate to disaster recovery zones through Terraform automation, reducing RTO/RPO windows from hours to minutes.

#### 2. **Kubernetes Multi-Cluster Management**
Enterprise Kubernetes environments (multiple clusters across regions/clouds) are provisioned and managed through Terraform. This includes:
- EKS cluster creation with proper networking and IAM configurations
- CNI plugin deployment and network policies
- Istio service mesh installation across clusters
- Cross-cluster traffic policies

#### 3. **CI/CD Pipeline Infrastructure as Code**
Entire CI/CD ecosystems—GitLab runners, Jenkins agents, container registries, artifact repositories—are managed as code. This enables:
- Ephemeral CI/CD infrastructure for security
- Rapid scaling of build agents during peak hours
- Infrastructure changes reviewed in pull requests before merge

#### 4. **Financial Service Compliance-Driven Infrastructure**
Highly regulated environments (PCI-DSS, HIPAA, SOC 2) use Terraform to enforce:
- Encryption at rest and in transit
- VPC isolation with strict security group rules
- Audit logging and monitoring across all resources
- Compliance checks as part of Terraform plan stage

#### 5. **Microservices Migration from Monolith**
Large-scale refactoring from monolithic to microservices architecture relies on Terraform to:
- Provision individual service VPCs with proper peering
- Set up service discovery (Consul, Kubernetes DNS)
- Configure load balancers with dynamic backend registration
- Manage database replicas for each service tier

### Where It Typically Appears in Cloud Architecture

In modern cloud architecture, Terraform occupies a critical position:

```
Version Control (Git)
       ↓
Terraform Code (main.tf, variables.tf, outputs.tf)
       ↓
CI/CD Pipeline (GitHub Actions, GitLab CI, Jenkins)
       ↓
Terraform Plan (Review Changes)
       ↓
Approval Workflow (Human Gate)
       ↓
Terraform Apply (Infrastructure Update)
       ↓
Cloud Provider APIs (AWS, Azure, GCP)
       ↓
Live Infrastructure
```

Terraform is typically the **source of truth** for:
- Network infrastructure (VPCs, subnets, route tables)
- Compute resources (EC2, RDS, Kubernetes clusters)
- IAM policies and role definitions
- Monitoring and logging infrastructure
- Storage and database provisioning

---

## Foundational Concepts

### Architecture Fundamentals

#### 1. **Terraform State Management**

Terraform maintains a **state file** (typically `terraform.tfstate`) that represents the current state of infrastructure. This is fundamentally different from imperative scripts, which have no inherent state tracking.

**Key Characteristics:**

- **Single Source of Truth**: The state file is the definitive record of what infrastructure exists
- **Remote State**: Production environments use remote state backends (S3, Azure Storage, Terraform Cloud) with locking mechanisms
- **State Separation**: Multiple workspaces/directories manage state isolation (dev, staging, prod)
- **Sensitive Data**: Passwords, API keys are encrypted in state files (usually at rest, always in transit over HTTPS)

**State File Structure Example:**
```json
{
  "version": 4,
  "terraform_version": "1.5.0",
  "resources": [
    {
      "type": "aws_instance",
      "name": "web_server",
      "instances": [
        {
          "attributes": {
            "id": "i-1234567890abcdef0",
            "instance_type": "t3.micro",
            "private_ip": "10.0.1.50"
          }
        }
      ]
    }
  ]
}
```

#### 2. **Module-Based Architecture**

Enterprise Terraform implementations use **modules** for scalability:

- **Root Module**: Main Terraform code that orchestrates infrastructure
- **Child Modules**: Reusable, versioned code for specific infrastructure patterns (e.g., `vpc-module`, `eks-cluster-module`)
- **Module Registry**: Internal/public registries store tested modules with documentation
- **Module Versioning**: Semantic versioning ensures compatibility and enables controlled upgrades

**Example Module Structure:**
```
terraform-modules/
├── vpc/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   └── README.md
├── rds-cluster/
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
└── eks-cluster/
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

#### 3. **Provider and Resource Abstraction**

Terraform providers are:
- **Abstraction Layers**: Abstract cloud APIs into Terraform resources
- **Versioned**: Each provider version supports different resource types and attributes
- **Cross-platform**: Single HCL syntax works across AWS, Azure, GCP, Kubernetes, etc.

**Example:**
```hcl
provider "aws" {
  region = var.aws_region
  default_tags {
    tags = {
      Environment = var.environment
      ManagedBy   = "terraform"
      CostCenter  = var.cost_center
    }
  }
}
```

#### 4. **Declarative vs State Reconciliation**

Unlike imperative approaches, Terraform:
1. Reads current infrastructure state
2. Compares desired state (code) with actual state (state file)
3. Generates a plan showing exactly what will change
4. Applies only the changes needed

This **three-step model** (read → plan → apply) is fundamental to Terraform's reliability.

### DevOps Principles

#### 1. **Infrastructure as Code (IaC) First**

Terraform embodies several critical DevOps principles:

- **Version Control Everything**: Infrastructure configs in Git with commit history
- **Code Reviews**: Pull requests for infrastructure changes enable peer review
- **Continuous Deployment**: Automated pipelines validate and deploy infrastructure
- **Immutability**: Blue-green deployments update entire infrastructure stacks atomically

#### 2. **Separation of Concerns**

Production-grade Terraform separates:

- **Variables** (`variables.tf`): Input parameters, environment-specific values
- **Configuration** (`main.tf`, `vpc.tf`, `compute.tf`): Resource definitions
- **Outputs** (`outputs.tf`): Values exported for downstream consumption
- **State** (remote backend): Managed separately from code

**Example Separation:**
```bash
└── terraform/
    ├── environments/
    │   ├── dev/
    │   │   ├── terraform.tfvars
    │   │   └── backend.tf
    │   └── prod/
    │       ├── terraform.tfvars
    │       └── backend.tf
    ├── modules/
    │   └── vpc/
    └── shared/
        └── variables.tf
```

#### 3. **Immutable Infrastructure**

Terraform enables **immutable infrastructure patterns**:

- Resources are **replaced** rather than modified in-place (when using `create_before_destroy`)
- Configuration changes trigger new resource creation, not in-place updates
- Rollback is a matter of applying a previous Terraform version
- Reduces configuration drift and unpredictable system states

```hcl
lifecycle {
  create_before_destroy = true
}
```

#### 4. **Declarative Configuration**

Terraform is declarative, meaning:

- **You specify the end state, not the steps**: "I want 3 EC2 instances with 20GB volume"
- **Terraform determines how to achieve it**: Creating only missing instances
- **Convergence**: Running the same code twice produces the same result
- **No manual steps**: Infrastructure is created programmatically, not through console clicks

### Best Practices

#### 1. **Remote State with Locking**

Production environments must use remote state backends with locking:

```hcl
terraform {
  backend "s3" {
    bucket         = "terraform-state-prod"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}
```

**Why?**
- Multiple team members access state concurrently
- Prevents concurrent modifications that corrupt state
- Enables encryption of sensitive data (passwords, API keys)
- Provides audit trail (CloudTrail for S3 access)

#### 2. **Variable Validation and Type Constraints**

Use strict input validation to catch errors early:

```hcl
variable "instance_count" {
  type        = number
  description = "Number of EC2 instances to create"
  default     = 3

  validation {
    condition     = var.instance_count > 0 && var.instance_count <= 100
    error_message = "Instance count must be between 1 and 100."
  }
}

variable "environment" {
  type = string
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}
```

#### 3. **Workspace Isolation (Environment Strategy)**

Separate state files for dev/staging/prod:

```bash
terraform workspace new dev
terraform workspace new staging
terraform workspace new prod
terraform workspace select prod
```

**Advanced Pattern Using Directories:**
```
terraform/
├── dev/
│   ├── main.tf
│   └── terraform.tfvars
├── staging/
│   ├── main.tf
│   └── terraform.tfvars
└── prod/
    ├── main.tf
    └── terraform.tfvars
```

#### 4. **Tagging Strategy**

Enforce consistent tagging for cost allocation and governance:

```hcl
locals {
  common_tags = {
    Environment        = var.environment
    ManagedBy         = "terraform"
    Project           = var.project_name
    CostCenter        = var.cost_center
    CreatedDate       = formatdate("YYYY-MM-DD", timestamp())
    ChangeTicket      = var.change_ticket_id
  }
}

resource "aws_instance" "app_server" {
  # ... other configuration ...
  
  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-app-server"
      Role = "application"
    }
  )
}
```

#### 5. **Plan Review Process**

Always review `terraform plan` output before applying:

```bash
terraform plan -out=tfplan
# Review output carefully, especially:
# - Resources being destroyed
# - Database modifications
# - Security group changes
# - IAM permission changes

terraform apply tfplan
```

#### 6. **Sensitive Output Masking**

Protect sensitive values in outputs:

```hcl
output "database_password" {
  value       = aws_rds_cluster.main.master_password
  sensitive   = true
  description = "RDS master password (sensitive)"
}

output "api_key" {
  value       = aws_secretsmanager_secret_version.api_key.secret_string
  sensitive   = true
}
```

#### 7. **Resource Targeting (Careful Use)**

Target specific resources only when necessary (avoid in CI/CD):

```bash
# Only creates the VPC (dangerous - breaks dependencies)
terraform apply -target=aws_vpc.main

# Use with extreme caution and ALWAYS verify impacts
terraform plan -target=aws_security_group.app_sg -out=tfplan
```

### Common Misunderstandings

#### 1. **"Terraform State is Optional"**

**Misconception**: "I can delete the state file; Terraform will just recreate it."

**Reality**:
- State file is the **mapping between code and real resources**
- Deleting state creates **orphaned resources** (still running, not managed by Terraform)
- Results in **duplicate resources** when Terraform tries to recreate them
- **Cost overruns** from untracked resources

**Correct Practice**: Always backup state, never delete it.

#### 2. **"Terraform is Just a Provisioning Tool"**

**Misconception**: "Terraform only creates infrastructure; configuration management tools (Ansible, Chef) handle the rest."

**Reality**:
- Terraform can manage **application configuration** through user data, provisioners, or remote-exec
- Terraform + cloud-init handles most configuration needs efficiently
- Mixing provisioning tools increases complexity and failure points
- Modern practice: Use Terraform for provisioning + Kubernetes/container orchestration for configuration

#### 3. **"Terraform Changes are Always Safe"**

**Misconception**: "Since Terraform shows a plan, changes are always safe to apply."

**Reality**: Some changes have **hidden consequences**:
- Modifying RDS instance type **causes downtime** (requires default behavior to apply immediately)
- Changing VPC CIDR **requires resource replacement** (break existing connections)
- Security group rule modifications **can block traffic immediately**
- Always understand the `lifecycle` behaviors for critical resources

#### 4. **"Remote State is Too Complex; Keep State Local"**

**Misconception**: "Local state files are simpler and safer."

**Reality**:
- **Local state lacks concurrency protection**: Multiple team members cause corruption
- **No state locking**: Race conditions lose data
- **No backup**: Laptop failure = infrastructure loss
- **No access control**: Anyone with file access can modify infrastructure
- **Production-grade requirement**: All production uses remote state with locking

#### 5. **"Terraform Doesn't Work with Dynamic Infrastructure"**

**Misconception**: "If infrastructure changes outside of Terraform, Terraform can't handle it."

**Reality**:
- Terraform **detects drift** with `terraform refresh`
- Use `data` sources to **read existing infrastructure**
- `terraform import` **brings existing resources** under Terraform management
- Terraform is **flexible enough** for gradual adoption (hybrid manual + IaC)

#### 6. **"Modules are Optional"**

**Misconception**: "Creating monolithic Terraform files is acceptable."

**Reality**:
- **Monolithic files become unmaintainable** at scale (500+ resources)
- **Modules enable code reuse** across projects
- **Modules provide documentation** and standardization
- **Lack of modules leads to:**
  - Inconsistent implementations across teams
  - Duplicated code (violates DRY principle)
  - Difficulty in onboarding new engineers
  - Reduced testing and validation

**Correct Practice**: Module-first approach from the start.

---

## Subtopic: Declarative vs Imperative Approaches

### Textual Deep Dive

#### Architecture Role

Terraform's declarative approach fundamentally changes how infrastructure is expressed and managed:

**Declarative (Terraform):**
- Describes the **desired end state** of infrastructure
- Engineer specifies "what" should exist, not "how" to create it
- Terraform determines execution path based on current state
- Convergent: Running the same code multiple times produces identical results

**Imperative (Traditional Scripts):**
- Describes step-by-step **procedural steps** to achieve infrastructure
- Engineer writes scripts that execute commands in sequence (Bash, Python, Ansible)
- Each script execution depends on initial conditions
- No inherent state tracking or idempotency

#### Internal Working Mechanism

**Declarative Processing Pipeline:**

```
Step 1: Parse HCL Code
   ↓
Step 2: Build Resource Graph (dependency resolution)
   ↓
Step 3: Load Current State (from state file or remote backend)
   ↓
Step 4: Compare Desired (code) vs Actual (state)
   ↓
Step 5: Generate Execution Plan (what will change)
   ↓
Step 6: Execute Changes (call provider APIs)
   ↓
Step 7: Update State File (reflects new reality)
```

The declarative model allows Terraform to:
1. **Understand intent** from code structure
2. **Detect missing resources** (compare desired vs actual)
3. **Detect extra resources** (orphaned - not in code)
4. **Determine change order** automatically through dependency graphs
5. **Validate changes** before execution

**Comparison with Imperative:**

Imperative approach lacks automatic state management:
```bash
# Imperative script
aws ec2 run-instances ...  # Creates instance
# If run again, creates ANOTHER instance (no state tracking)
# Must manually track what was created
# Must write cleanup logic separately
```

#### Production Usage Patterns

**Pattern 1: GitOps Workflow**

Declarative nature enables GitOps:
- Git repository is source of truth
- Pull request = infrastructure review
- Merge = automated infrastructure deployment
- Rollback = revert commit

**Pattern 2: Multi-Environment Consistency**

```
Dev Code → terraform plan → Review → Deploy
Staging Code → terraform plan → Review → Deploy  
Prod Code → terraform plan → Review → Deploy
```

Same code ensures consistency across environments.

**Pattern 3: Disaster Recovery and Reproducibility**

- Infrastructure defined in code means complete reproducibility
- New region deployment: `point to different state file, update region variables, apply`
- No manual documentation needed; code is the documentation

**Pattern 4: Large-Scale Deployments**

Managing 1000+ resources:
- Imperative scripts become unmaintainable
- Declarative allows logical organization through modules
- Dependency management happens automatically

#### DevOps Best Practices

1. **Embrace the Declarative Model**
   - Don't write Terraform to emulate imperative scripts
   - Use `for_each` and `count` instead of looping with state
   - Leverage module composition instead of procedural scripts

2. **Use Local Values and Data Sources**
   ```hcl
   # GOOD: Declarative calculation
   locals {
     instance_count = var.enable_auto_scaling ? 5 : 1
   }

   # BAD: Procedural logic
   resource "aws_instance" "app" {
     # Script-like logic here
   }
   ```

3. **Respect Dependency Graphs**
   - Use `depends_on` only when implicit dependencies aren't detected
   - Allow Terraform to determine optimal execution order
   - Never force sequential execution unless required

4. **Plan Reviews Are Critical**
   - Declarative changes are deterministic, but scope matters
   - Review each `terraform plan` to understand cascade effects
   - Particularly critical for breaking changes (deletion, recreation)

#### Common Pitfalls

**Pitfall 1: Mixing Imperative Thinking in Declarative Code**

```hcl
# WRONG: Imperative thinking (step-by-step)
resource "aws_instance" "server1" {
  ami           = "ami-12345"
  instance_type = "t3.micro"
}

resource "aws_instance" "server2" {
  ami           = "ami-12345"
  instance_type = "t3.micro"
  depends_on    = [aws_instance.server1]  # Incorrect: no logical reason
}

# CORRECT: Declarative (declare structure, let Terraform order it)
resource "aws_instance" "servers" {
  count         = 2
  ami           = "ami-12345"
  instance_type = "t3.micro"
}
```

**Pitfall 2: Not Understanding State File Importance**

Imperative scripts don't maintain state, so engineers sometimes ignore Terraform's state file:

```bash
# WRONG: Manually changing resources, then running Terraform
aws ec2 modify-instance-attribute ...  # Manual change
terraform apply  # Terraform doesn't know about manual change
```

**Pitfall 3: Over-using Provisioners (Anti-pattern)**

```hcl
# WRONG: Using provisioners for configuration (imperative)
resource "aws_instance" "app" {
  ami = "ami-12345"

  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install python3",
      "pip3 install flask"
    ]
  }
}

# CORRECT: Use user_data or configuration management
resource "aws_instance" "app" {
  ami           = "ami-12345"
  user_data     = base64encode(file("${path.module}/init.sh"))
  # Or use Kubernetes/container orchestration
}
```

**Pitfall 4: Failed Assumption about Plan Safety**

```bash
# WRONG: Assuming terraform plan is always safe
terraform plan -out=tfplan
terraform apply tfplan  # Without full review
```

Some apparently innocent changes cause downtime:
- RDS instance modifications require downtime flags
- VPC CIDR changes require resource recreation
- Security group modifications can block traffic immediately

### Practical Code Examples

#### Example 1: Declarative Lambda Deployment with Dependencies

```hcl
# variables.tf
variable "function_code_path" {
  type    = string
  default = "./src/lambda"
}

variable "enable_api_gateway" {
  type    = bool
  default = true
}

# main.tf
# Create IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "lambda-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

# Create Lambda function (Terraform automatically waits for role to exist)
resource "aws_lambda_function" "api_handler" {
  function_name = "api-handler"
  role          = aws_iam_role.lambda_role.arn
  runtime       = "python3.11"
  handler       = "index.handler"

  filename         = "${path.module}/lambda_function.zip"
  source_code_hash = filebase64sha256("${path.module}/lambda_function.zip")

  environment {
    variables = {
      ENVIRONMENT = var.environment
    }
  }
}

# Create API Gateway (declarative - Terraform knows Lambda already exists)
resource "aws_apigatewayv2_api" "api" {
  count            = var.enable_api_gateway ? 1 : 0
  name             = "api-gateway"
  protocol_type    = "HTTP"
  target           = aws_lambda_function.api_handler.arn
}

# outputs.tf
output "lambda_function_arn" {
  value       = aws_lambda_function.api_handler.arn
  description = "ARN of the Lambda function"
}

output "api_endpoint" {
  value       = var.enable_api_gateway ? aws_apigatewayv2_api.api[0].api_endpoint : null
  description = "API Gateway endpoint (if enabled)"
}
```

**Key Declarative Elements:**
- No explicit ordering defined; Terraform determines IAM role must be created first
- API Gateway creation depends on Lambda's existence (implicit dependency)
- Conditional creation using `count` based on variable
- No procedural steps; just declare desired resources

#### Example 2: Declarative Multi-AZ RDS Cluster

```hcl
resource "aws_rds_cluster" "main" {
  cluster_identifier      = "production-cluster"
  availability_zones      = ["us-east-1a", "us-east-1b", "us-east-1c"]
  master_username         = "admin"
  master_password         = random_password.db_password.result
  database_name           = "appdb"
  backup_retention_period = 30
  preferred_backup_window = "03:00-04:00"
  skip_final_snapshot     = false
  final_snapshot_identifier_prefix = "rds-final-snapshot"

  # Declares desired state; Terraform ensures these properties
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]
  
  tags = local.common_tags
}

resource "aws_rds_cluster_instance" "instances" {
  count              = 3
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.r6g.xlarge"
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version

  instance_identifier = "prod-instance-${count.index + 1}"
}

resource "aws_security_group" "rds" {
  name        = "rds-security-group"
  description = "Security group for RDS cluster"

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Declarative monitoring
resource "aws_cloudwatch_metric_alarm" "db_cpu" {
  alarm_name          = "rds-cpu-high"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/RDS"
  period              = 300
  statistic           = "Average"
  threshold           = 80
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    DBClusterIdentifier = aws_rds_cluster.main.cluster_identifier
  }
}
```

**Declarative Benefits Shown:**
- Multi-AZ deployment specified declaratively (Terraform handles instance placement)
- Security groups declared; no manual attachment commands
- Monitoring/alarms declared as code
- If you need 5 instances instead of 3, change `count = 5` and apply (Terraform adds 2 new instances)

#### Example 3: CLI Commands Demonstrating Declarative Nature

```bash
# 1. Initial deployment - all resources created
terraform plan
# Output shows: Plan to add 8 resources

terraform apply
# All resources created in dependency order

# 2. Verify infrastructure
terraform show  # Shows current state
# Lists all 8 resources and their properties

# 3. Change: Add one more RDS instance (change count from 2 to 3)
vi main.tf  # Edit count = 3

terraform plan
# Output shows: Plan to add 1 resource (the additional RDS instance)
# Terraform knows it doesn't need to recreate the other 2 instances!

terraform apply
# Only the new instance is created
# Demonstrates declarative nature: Terraform compared desired (3) vs. actual (2)

# 4. Disaster recovery: Recreate in different region
terraform init -backend-config="bucket=other-region-bucket"
terraform apply
# Same code, different state file = complete infrastructure replica
```

### ASCII Diagrams

#### Diagram 1: Declarative vs Imperative Processing

```
DECLARATIVE (Terraform):
┌─────────────────────┐
│   HCL Code          │  "I want 3 EC2, RDS cluster, VPC"
│  (Desired State)    │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Terraform Analysis  │
│ - Parse code        │
│ - Build graph       │
│ - Determine order   │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Load Current State  │  State file shows: 3 EC2s, 0 RDS, 1 VPC
│  (Actual State)     │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Diff Calculation  │  Need: 1 RDS cluster (missing)
│  (Desired - Actual) │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Execution Plan     │  Plan: Create RDS cluster with proper
│  (terraform plan)   │  backups, encryption, monitoring
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Apply Changes     │
│  Call Provider APIs │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│   Update State      │  State now: 3 EC2s, 1 RDS, 1 VPC
└─────────────────────┘


IMPERATIVE (Bash Scripts):
┌─────────────────────┐
│   Shell Script      │
│  Step 1: Create VPC │
│  Step 2: Create SG  │
│  Step 3: Create EC2 │  "Do these steps in this order"
│  Step 4: Create RDS │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Execute Script     │
│  Run each command   │
│  No state tracking  │
│  No change tracking │
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│ Manual Verification │  "Did all steps succeed?"
│ & Documentation     │  "What was created?"
└─────────────────────┘

Problem: Run again? Creates DUPLICATE resources!
```

#### Diagram 2: Dependency Graph Resolution

```
Declarative Code Structure:

resource "aws_vpc" "main" {...}          # No dependencies
resource "aws_subnet" "app" {...}        # Depends on: VPC
resource "aws_security_group" "app" {...} # Depends on: VPC
resource "aws_instance" "web" {...}      # Depends on: Subnet, SG
resource "aws_lb" "main" {...}           # Depends on: Subnet
resource "aws_lb_target_group" "web" {...} # Depends on: VPC


Terraform Builds Dependency Graph:

              ┌────────────────────┐
              │   aws_vpc (main)   │
              └─────────┬──────────┘
                        │
           ┌────────────┼────────────┐
           │            │            │
           ▼            ▼            ▼
    aws_subnet    aws_security    aws_lb_target_
      (app)         group (app)      group
           │            │
           └────────┬───┘
                    │
                    ▼
              aws_instance
                 (web)

Execution Order Determined Automatically:
1. aws_vpc (main)
2. aws_subnet (app) + aws_security_group (app) + aws_lb_target_group (in parallel)
3. aws_lb (main) + aws_instance (web) (in parallel)

No manual ordering required; Terraform optimizes parallelization!
```

#### Diagram 3: State File as Bridge Between Code and Reality

```
┌──────────────────────┐
│   Terraform Code     │
│   (HCL)              │
│                      │
│ resource "aws..." {  │
│   instance_type =    │
│   "t3.large"         │
│ }                    │
└──────────┬───────────┘
           │
           │ (Desired State)
           │
     ┌─────▼──────┐
     │             │
     │  Terraform  │
     │  Engine     │ ◄─── Compares: Desired vs Actual
     │             │      Generates: Execution Plan
     │             │      Executes: Changes  
     │             │      Updates: State
     │             │
     └─────┬──────┘
           │
           │ (Actual State)
           │
  ┌────────▼──────────────────┐
  │  terraform.tfstate        │
  │  (Remote Backend)         │
  │                           │
  │  "aws_instance": {        │
  │    "id": "i-1234567890", │
  │    "instance_type": ...   │
  │  }                        │
  └────────┬──────────────────┘
           │
           │
  ┌────────▼──────────────────┐
  │  AWS Infrastructure       │
  │  (Real Resources)         │
  │                           │
  │  EC2 Instance i-1234...   │
  │  Type: t3.large           │
  │  Status: running          │
  └───────────────────────────┘
```

---

## Subtopic: Idempotency in IaC

### Textual Deep Dive

#### Architecture Role

Idempotency is the **mathematical property that an operation produces the same result regardless of how many times it is applied**. In infrastructure context:

**Definition**: Running the same Terraform code multiple times produces identical infrastructure without unintended side effects.

**Why It Matters in DevOps:**
- **Safety**: Multiple applies during maintenance don't break infrastructure
- **Recoverability**: If apply is interrupted, rerun completes safely
- **Automation**: CI/CD pipelines can apply configuration without manual intervention
- **Testing**: Engineers can test infrastructure changes locally without fear
- **Consistency**: Idempotent operations guarantee convergence

#### Internal Working Mechanism

**Idempotent Operation Pattern:**

```
First Run:
┌─────────────────────┐
│  Desired State      │  Create VPC: 10.0.0.0/16
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Check Actual State │  VPC doesn't exist
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Perform Action     │  CREATE VPC
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Verify Result      │  VPC created successfully
└─────────────────────┘

Second Run (without any code changes):
┌─────────────────────┐
│  Desired State      │  Create VPC: 10.0.0.0/16 (same)
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Check Actual State │  VPC ALREADY EXISTS (same state)
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Compare            │  Desired == Actual → No action needed
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Result             │  terraform apply succeeds (no changes)
└─────────────────────┘
```

**Key Mechanisms Enabling Idempotency:**

1. **State File Tracking**
   - Records what was previously created
   - On subsequent runs, Terraform checks if resource already exists
   - Only creates/modifies/deletes based on actual state vs desired state

2. **Resource Uniqueness Identifiers**
   - AWS resources have unique IDs (i-1234567890 for EC2)
   - Terraform maps code resources to actual resources via state
   - Same code `aws_instance.web` always maps to same instance

3. **Idempotent API Design**
   - Cloud provider APIs are designed for idempotency
   - Creating same resource twice returns existing resource
   - Some operations include "upsert" semantics (create or update)

**Example: Creating an S3 Bucket (Idempotent)**

```hcl
resource "aws_s3_bucket" "logs" {
  bucket = "company-logs-2024"
}

# Run 1: Bucket doesn't exist → Created
# terraform apply → S3 bucket "company-logs-2024" created

# Run 2: Bucket exists with same name → No action
# terraform apply → No changes (bucket matches desired state)

# Run 3: Add versioning (change code)
# terraform apply → Bucket updated with versioning (only change applied)
```

#### Production Usage Patterns

**Pattern 1: Safe Automated CI/CD**

Idempotency enables safe CI/CD:

```bash
# CI/CD Pipeline Step: Apply using Terraform
terraform plan  # Review changes
terraform apply  # Apply changes

# If apply fails halfway through:
# - Some resources created
# - Some resources not created
# Rerunning apply:
# - Skips already-created resources
# - Creates remaining resources
# - Converges to correct state
```

**Pattern 2: Configuration Drift Remediation**

Operators accidentally modify resources manually. Idempotency enables automatic remediation:

```bash
# Engineer accidentally modified security group via console
aws ec2 authorize-security-group-ingress ...
# Added rules not in Terraform code

# Run Terraform:
terraform plan
# Detects drift: Extra rules in actual vs code

terraform apply
# Removes manually-added rules
# Converges to code-specified state
```

**Pattern 3: Scheduled Configuration Validation**

Run Terraform periodically to ensure infrastructure matches code:

```bash
# Cron job: Every hour
0 * * * * cd /infrastructure && terraform apply

# Effect:
# - Idempotent operations mean no disruption if unchanged
# - If drift detected, automatically corrects
# - Continuous compliance with code-specified state
```

**Pattern 4: Blue-Green Deployment Stability**

Idempotency ensures blue-green deployments stabilize:

```
Blue Version (v1):
  - Load Balancer routes to Blue
  - Infrastructure defined in code
  - terraform apply applied twice (idempotent)

Green Version (v2):
  - New infrastructure provisioned via code
  - terraform apply ensures convergence
  - Load Balancer configuration changed
  - terraform apply applied twice (idempotent)

Rollback:
  - Revert load balancer configuration change
  - terraform apply (idempotent)
  - Back to Blue (no resource recreation needed)
```

#### DevOps Best Practices

1. **Always Test Idempotency Locally**
   ```bash
   # First apply
   terraform apply
   
   # Second apply on same state (should show no changes)
   terraform apply
   # terraform shows: No changes. Infrastructure is up-to-date.
   ```

2. **Understand Non-Idempotent Operations**
   
   Some Terraform resources have non-idempotent behaviors:
   
   ```hcl
   # NON-IDEMPOTENT: Creates new instance each apply
   resource "aws_instance" "app" {
     ami = data.aws_ami.latest.id  # Latest AMI ID changes over time
     # Each apply might get different AMI ID
   }
   
   # IDEMPOTENT: Pins specific AMI
   resource "aws_instance" "app" {
     ami = "ami-0c55b159cbfafe1f0"  # Specific AMI ID
     # Repeated applies use same AMI
   }
   ```

3. **Handle Timestamp-Based Attributes Carefully**
   
   ```hcl
   # NON-IDEMPOTENT: Timestamp changes on each apply
   resource "aws_instance" "web" {
     tags = {
      LastModified = timestamp()  # Changes every apply
    }
   }
   
   # IDEMPOTENT: Use time_static for fixed value
   resource "time_static" "build_time" {}
   
   resource "aws_instance" "web" {
     tags = {
       LaunchDate = time_static.build_time.rfc3339
     }
   }
   ```

4. **Use Ignore Changes for Noise**
   
   ```hcl
   resource "aws_instance" "web" {
     ami           = "ami-12345"
     instance_type = "t3.micro"
     
     # Some attributes change outside Terraform (system updates)
     lifecycle {
       ignore_changes = [ami]  # Ignore AMI changes not in code
     }
   }
   ```

5. **Prevent Unwanted Resource Replacement**
   
   ```hcl
   # Some changes force replacement (breaks idempotency perception)
   resource "aws_security_group" "app" {
     name = "app-sg"  # If changed, forces new security group
     
     # Problematic: name is immutable, existing SG keeps old name
     # Better: Use computed name
   }
   
   # Better approach:
   resource "aws_security_group" "app" {
     description = "Security group for app"
     vpc_id      = aws_vpc.main.id
     # Let AWS assign name automatically
     
     lifecycle {
       create_before_destroy = true
     }
   }
   ```

#### Common Pitfalls

**Pitfall 1: Assuming All Resources Are Idempotent**

Some AWS resources have non-idempotent behaviors:

```hcl
# NON-IDEMPOTENT: RDS password change
resource "aws_rds_cluster" "main" {
  master_password = random_password.db.result  # Regenerates each apply
  # Running apply twice modifies the password both times!
}

# IDEMPOTENT: Store password in Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name = "db/master/password"
}

resource "aws_rds_cluster" "main" {
  master_password = aws_secretsmanager_secret.db_password.random_password
  # First apply: Creates secret and cluster
  # Second apply: No changes (password not regenerated)
}
```

**Pitfall 2: Mutable Configurations Breaking Idempotency**

```hcl
# NON-IDEMPOTENT: AMI data source returns latest
data "aws_ami" "ubuntu" {
  most_recent = true
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
}

resource "aws_instance" "app" {
  ami = data.aws_ami.ubuntu.id  # Changes when new Ubuntu version released
  # Second apply might use newer AMI, recreating instance!
}

# IDEMPOTENT: Pin specific AMI
resource "aws_instance" "app" {
  ami = "ami-0c55b159cbfafe1f0"  # Specific AMI
  # Idempotent: Same AMI used each apply
}
```

**Pitfall 3: Provisioners Breaking Idempotency**

```hcl
# NON-IDEMPOTENT: Provisioner runs even if resource unchanged
resource "aws_instance" "web" {
  ami = "ami-12345"
  
  provisioner "remote-exec" {
    inline = [
      "echo $(date) > /tmp/deployed_at.txt"  # Changes timestamp
    ]
  }
}
# Each apply executes provisioner, creating new timestamp!

# IDEMPOTENT: Use user_data instead
resource "aws_instance" "web" {
  ami       = "ami-12345"
  user_data = base64encode(file("${path.module}/init.sh"))
  # Executed only once during instance creation
}
```

**Pitfall 4: External Data Dependencies**

```hcl
# NON-IDEMPOTENT: External script output varies
data "external" "config" {
  program = ["python3", "${path.module}/get_config.py"]
}

resource "aws_instance" "app" {
  instance_type = data.external.config.result["instance_type"]
  # If script output changes, recreates instance!
}

# IDEMPOTENT: Use fixed configuration
resource "aws_instance" "app" {
  instance_type = var.instance_type  # From variables
  # Idempotent: Variable doesn't change unless explicitly modified
}
```

### Practical Code Examples

#### Example 1: Idempotent Auto-Scaling Group with Launch Template

```hcl
# Define launch template (immutable - changes create new version)
resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = "ami-0c55b159cbfafe1f0"  # Pinned AMI
  instance_type = "t3.medium"

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "app-server"
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Auto-Scaling Group (idempotent - updates ASG, replaces instances if needed)
resource "aws_autoscaling_group" "app" {
  name                = "app-asg-${aws_launch_template.app.latest_version_number}"
  vpc_zone_identifier = var.subnet_ids
  min_size            = 2
  max_size            = 5
  desired_capacity    = 3

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"  # Uses latest template version
  }

  health_check_type         = "ELB"
  health_check_grace_period = 300

  tag {
    key                 = "Name"
    value               = "app-asg-instance"
    propagate_at_launch = true
  }

  lifecycle {
    create_before_destroy = true
  }
}

# Running multiple times:
# Apply 1: Creates launch template and ASG
# Apply 2: No changes (identical configuration)
# Apply 3 (after changing instance_type): 
#   - Creates new launch template version
#   - Updates ASG (references new template)
#   - Instances gradually replaced (idempotent)
```

#### Example 2: Idempotent RDS with Fixed Configuration

```hcl
# DO NOT use random_password here!
# Instead, use AWS Secrets Manager for password generation
resource "aws_secretsmanager_secret" "rds_password" {
  name_prefix             = "rds-master-password-"
  recovery_window_in_days = 7
}

resource "aws_secretsmanager_secret_version" "rds_password" {
  secret_id       = aws_secretsmanager_secret.rds_password.id
  secret_string   = var.rds_master_password  # Managed outside Terraform
  # OR automatically generated once:
  # secret_string   = random_password.db_password.result
}

resource "aws_rds_cluster" "main" {
  cluster_identifier              = "production-cluster"
  availability_zones              = ["us-east-1a", "us-east-1b"]
  master_username                 = "admin"
  master_password                 = var.rds_master_password  # From variables/env
  database_name                   = "appdb"
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.main.name
  backup_retention_period         = 30
  preferred_backup_window         = "03:00-04:00"

  # Idempotent: Database specification is fixed
  db_subnet_group_name = aws_db_subnet_group.main.name
  
  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  skip_final_snapshot = false
  final_snapshot_identifier_prefix = "rds-snapshot"

  # Prevent unintended recreation
  lifecycle {
    ignore_changes = [
      master_password,  # Manage password separately
      availability_zones  # Handled by AWS
    ]
  }
}

resource "aws_rds_cluster_instance" "instances" {
  count              = 3
  cluster_identifier = aws_rds_cluster.main.id
  instance_class     = "db.r6i.xlarge"  # Fixed class
  engine             = aws_rds_cluster.main.engine
  engine_version     = aws_rds_cluster.main.engine_version
  instance_identifier = "prod-instance-${count.index + 1}"

  monitoring_interval             = 60
  monitoring_role_arn             = aws_iam_role.rds_monitoring.arn
  performance_insights_enabled    = true
  performance_insights_retention_period = 7
}

# Idempotency guarantee:
# - Multiple applies don't modify RDS configuration
# - Password changes managed separately (via variables)
# - Instances maintain consistent configuration
```

#### Example 3: CLI Commands Demonstrating Idempotency

```bash
# Initialize and configure
terraform init
terraform plan
# Output: Plan to add 15 resources

terraform apply
# Output: Apply complete! Resources added: 15

# ============ FIRST RERUN (without changes) ============
terraform plan
# Output: No changes. Infrastructure is up-to-date.
No changes to infrastructure. All resources are up-to-date.

terraform apply
# Output: Apply complete! Resources added: 0. So the changes are not yet applied...Apply complete! Resources added: 0.
# Key: No resources modified, added, or destroyed!

# ============ MODIFY CONFIGURATION ============
echo 'desired_capacity = 5' >> main.tf  # Change ASG size

terraform plan
# Output: Plan to modify 1 resource
#   ~ aws_autoscaling_group.app
#       desired_capacity: 3 -> 5

terraform apply
# Output: Apply complete! Resources modified: 1.

# ============ RERUN WITHOUT CHANGES (idempotent) ============
terraform plan
# Output: No changes. Infrastructure is up-to-date.

terraform apply
# Output: Apply complete! Resources added: 0.
# Demonstrates idempotency: Repeated applies don't re-modify resources

# ============ VERIFY STATE CONSISTENCY ============
terraform refresh  # Re-read actual infrastructure
terraform plan     # Compare to code
# Output: No changes - application is idempotent!
```

### ASCII Diagrams

#### Diagram 1: Idempotent vs Non-Idempotent Operations

```
IDEMPOTENT Operation:

Apply #1                 Apply #2                 Apply #3
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│ Code:       │         │ Code:       │         │ Code:       │
│ EC2 count=2 │         │ EC2 count=2 │         │ EC2 count=2 │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                       │
       ▼                       ▼                       ▼
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│ Check State │         │ Check State │         │ Check State │
│ 0 instances │         │ 2 instances │         │ 2 instances │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                       │
       ▼                       ▼                       ▼
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│ Action:     │         │ Action:     │         │ Action:     │
│ Create 2    │         │ (None)      │         │ (None)      │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                       │
       ▼                       ▼                       ▼
   Result:               Result:              Result:
  2 instances          No change          No change
   created            (Idempotent)        (Idempotent)


NON-IDEMPOTENT Operation (with random_password):

Apply #1                 Apply #2                 Apply #3
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│ Code:       │         │ Code:       │         │ Code:       │
│ RDS pwd=    │         │ RDS pwd=    │         │ RDS pwd=    │
│ random()    │         │ random()    │         │ random()    │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                       │
       ▼                       ▼                       ▼
  pwd = "A1X9B2"        pwd = "M3K8L5"        pwd = "P7Q2R6"
       │                       │                       │
       ▼                       ▼                       ▼
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│ Create RDS  │         │ Update RDS  │         │ Update RDS  │
│ pwd=A1X9B2  │         │ pwd=M3K8L5  │         │ pwd=P7Q2R6  │
└──────┬──────┘         └──────┬──────┘         └──────┬──────┘
       │                       │                       │
       ▼                       ▼                       ▼
   Result:               Result:              Result:
  RDS created         Password changed    Password changed
 (Applied)          (NOT IDEMPOTENT)    (NOT IDEMPOTENT)
```

#### Diagram 2: Idempotency with Convergence

```
Starting from Corrupt/Drift State:

Actual Infrastructure (Drift exists):
  EC2 Instance i-1234: t3.micro
  EC2 Instance i-5678: t3.small  ← Manual change! Not in code
  RDS Cluster: 30 backup days
  Security Group: Extra rule allowing 0.0.0.0/0

Running terraform apply (with correct code):

┌──────────────────────────────────────────┐
│  Apply Run #1                            │
│  ┌────────────────────────────────────┐  │
│  │ Desired (Code):                    │  │
│  │  - 2x t3.micro EC2 instances       │  │
│  │  - 30 day RDS backups              │  │
│  │  - No 0.0.0.0/0 security rules     │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ Actions Taken:                     │  │
│  │  - Modify i-5678: t3.small → t3.m  │  │ Corrects drift
│  │  - Delete extra SG rule            │  │
│  │  - No RDS changes needed           │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Result: Infrastructure converges!      │
└──────────────────────────────────────────┘

Running terraform apply (second time, without code changes):

┌──────────────────────────────────────────┐
│  Apply Run #2                            │
│  ┌────────────────────────────────────┐  │
│  │ Check State: All matches code      │  │
│  │ No drift detected                  │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ Actions Taken: (None)              │  │
│  │ Infrastructure already correct     │  │
│  └────────────────────────────────────┘  │
│                                          │
│  Result: Idempotent! No changes         │
└──────────────────────────────────────────┘
```

---

## Subtopic: Drift

### Textual Deep Dive

#### Architecture Role

**Drift Definition**: The difference between infrastructure defined in Terraform code (desired state) and the actual infrastructure deployed in cloud providers (actual state).

Drift is a critical concept in infrastructure management because:

1. **State Divergence**: Infrastructure can change independently of Terraform
2. **Compliance Risk**: Actual infrastructure may violate policies defined in code
3. **Cost Implications**: Unwanted resources remain running, incurring charges
4. **Operational Visibility**: Teams unaware of divergence make decisions based on incorrect assumptions
5. **Disaster Recovery**: Drift makes infrastructure recovery more complex

**Types of Drift:**

| Drift Type | Cause | Example |
|-----------|-------|----------|
| **Intentional** | Manual emergency response | Scaling up ASG during incident |
| **Accidental** | Human error via console | Modifying security group rule |
| **Exploratory** | Testing via CLI | Creating test instances |
| **Malicious** | Unauthorized changes | Attacker modifying configurations |
| **Provider-initiated** | Cloud provider auto-actions | AWS auto-scaling terminating instance |

#### Internal Working Mechanism

**Drift Detection Process:**

```
Step 1: Read Current State File
┌──────────────────────────┐
│ terraform.tfstate        │
│ Shows state at last      │
│ successful apply         │
└────────┬─────────────────┘
         │
         ▼
Step 2: Refresh State (Read Actual Infrastructure)
┌──────────────────────────┐
│ Query AWS APIs           │
│ for each resource        │
│ Get actual properties    │
└────────┬─────────────────┘
         │
         ▼
Step 3: Update State File with Actual Values
┌──────────────────────────┐
│ terraform.tfstate        │
│ now reflects actual      │
│ infrastructure state     │
└────────┬─────────────────┘
         │
         ▼
Step 4: Parse Terraform Code
┌──────────────────────────┐
│ Read *.tf files          │
│ Extract desired state    │
│ (from code)              │
└────────┬─────────────────┘
         │
         ▼
Step 5: Compute Diff
┌──────────────────────────┐
│ Compare:                 │
│ Desired (code) vs        │
│ Actual (refreshed state) │
└────────┬─────────────────┘
         │
         ▼
Step 6: Report Drift
┌──────────────────────────┐
│ (a) No drift: Match      │
│ (b) Drift detected:      │
│     Show differences     │
└──────────────────────────┘
```

**Drift Detection Commands:**

```bash
# Method 1: Refresh + Plan
terraform refresh  # Read actual state
terraform plan     # Compare to code (shows drift)

# Method 2: Combined (newer approach)
terraform plan  # Implicitly refreshes state

# Output shows drift:
# ~ aws_instance.web
#   - instance_type: "t3.large" -> "t3.small"  (DRIFT!)
#   - tags.Owner: "alice" -> "bob"  (DRIFT!)
```

**State File During Drift:**

```json
// After initial apply:
{
  "resources": [
    {
      "type": "aws_instance",
      "name": "web",
      "instances": [
        {
          "attributes": {
            "id": "i-1234567890abcdef0",
            "instance_type": "t3.small",
            "availability_zone": "us-east-1a"
          }
        }
      ]
    }
  ]
}

// Manual change via console:
// aws ec2 modify-instance-attribute --instance-id i-1234567890abcdef0 --instance-type t3.large

// State file's perception:
// Still shows t3.small (OUT OF SYNC WITH REALITY!)

// After terraform refresh:
// Updated to reflect actual t3.large
```

#### Production Usage Patterns

**Pattern 1: Scheduled Drift Detection**

```bash
# Cron job: Check for drift every 6 hours
0 */6 * * * cd /infrastructure && \
  terraform plan -json | jq '.resource_changes[] | select(.change.actions != [])' \
  >> drift_log.json

# Alerts team if drift detected
```

**Pattern 2: Preventing Drift with Policies**

Organizations enforce:
1. All infrastructure changes MUST go through Terraform
2. Console access limited (read-only or restricted)
3. CI/CD pipeline validates code before deployment
4. Regular drift audits

**Pattern 3: Drift Remediation Workflow**

```
1. Drift Detected
   ↓
2. Investigate Root Cause
   - Was it manual? Which user?
   - Was it provider-initiated? (Auto-scaling, maintenance)
   - Is it intentional?
   ↓
3. Choose Resolution
   a) Update Code (if drift is desired)
      - Commit changes to code
      - terraform apply
   
   b) Revert to Code (if drift is accidental)
      - terraform apply (removes drift)
   
   c) Import Resource (if new resource needed)
      - terraform import aws_instance.new i-xyz
```

**Pattern 4: Zero-Downtime Drift Response**

Some drift requires careful handling:

```hcl
# Drift scenario: Manual scaling of ASG
# Actual: 10 instances
# Code: 3 instances

# Direct terraform apply risks:
# - Terminates 7 instances immediately
# - Potential service disruption

# Better approach:
resource "aws_autoscaling_group" "app" {
  desired_capacity = 10  # Update code to match actual first
  min_size         = 10
  max_size         = 15
}

terraform apply  # Converges state

# Then gradually reduce:
resource "aws_autoscaling_group" "app" {
  desired_capacity = 8   # Gradual reduction
}
# Repeat until reaching desired 3 instances
```

#### DevOps Best Practices

1. **Enable Drift Detection Regularly**
   ```bash
   # Automated scheduled checks
   - Run terraform plan daily
   - Generate drift reports
   - Alert on significant drift
   ```

2. **Understand Acceptable Drift**
   ```hcl
   # Some changes intentionally ignored
   resource "aws_instance" "app" {
     ami = "ami-12345"
     
     lifecycle {
       ignore_changes = [
         tags["LastUpdated"],  # System-managed tags acceptable
         root_block_device[0].volume_size  # Auto-expand acceptable
       ]
     }
   }
   ```

3. **Root Cause Analysis**
   - Track WHO made changes (CloudTrail, AWS Config)
   - Track WHAT was changed
   - Track WHEN it was changed
   - Determine if intentional or accidental

4. **Prevent Common Drift Causes**
   ```hcl
   # Drift cause: Auto-scaling modifying ASG
   # Prevention: Lock desired_capacity in code
   
   resource "aws_autoscaling_group" "app" {
     desired_capacity = 3
     min_size         = 3
     max_size         = 10  # Allows scaling, but reverts after
   }
   ```

5. **Version Control Configuration**
   - Every infrastructure change via Git
   - Code review before merge
   - Audit trail of who approved what

#### Common Pitfalls

**Pitfall 1: Ignoring Drift Until It's Critical**

Minor drift accumulates:

```
Week 1: One security group rule modified manually
Week 2: Three EC2 tags changed via console
Week 3: Database parameter modified
Week 4: Attempt to apply Terraform → Multiple conflicts

Better: Catch and fix drift immediately
```

**Pitfall 2: Not Distinguishing Between Drift Types**

```bash
# AWS auto-scaling terminates instance during maintenance
# This creates drift, but:
# - Terraform SHOULD replace it automatically
# - NOT a problem; expected behavior

# Manual instance termination via console
# This creates drift, and:
# - Indicates policy violation
# - Requires investigation

# Not investigating cost is lost understanding
```

**Pitfall 3: Drift Detection Without Remediation Plan**

```bash
terraform plan -json | jq '.resource_changes[]'
# Output shows 47 resources with drift
# Then: Silence... Nothing happens

# Better: Automated remediation workflow
# If drift within threshold: Auto-apply fix
# If drift exceeds threshold: Alert for manual review
```

**Pitfall 4: Accepting Drift When Updating Code**

```hcl
# WRONG: Observing drift, then updating code to match
resource "aws_security_group" "app" {
  ingress {
    from_port = 443
    to_port   = 443
    # These were manually added (drift)
    # Engineer updates code to match:
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Codifies manual change
  }
}

# CORRECT: Review drift thoroughly before codifying
# Determine: Was manual change necessary? Approved? In code?
```

**Pitfall 5: Blanket Ignore Changes**

```hcl
# WRONG: Ignoring too many properties
life cycle {
  ignore_changes = all  # Ignores ALL changes!
}
# Defeats purpose of Terraform (no drift detection)

# CORRECT: Ignore specific, intentional changes only
lifecycle {
  ignore_changes = [
    tags["ManagedBy"],  # AWS service adds this
    instance_state     # ASG modifies this
  ]
}
```

### Practical Code Examples

#### Example 1: Detecting Drift in a Multi-Layer Stack

```hcl
# main.tf: Complete stack
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "production-vpc"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  tags = {
    Name = "public-subnet"
  }
}

resource "aws_security_group" "app" {
  name        = "app-sg"
  description = "Application security group"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_instance" "app" {
  ami                    = "ami-0c55b159cbfafe1f0"
  instance_type          = "t3.medium"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.app.id]

  tags = {
    Name    = "app-server"
    Owner   = "platform-team"
    Env     = "production"
    Version = "1.0"
  }
}
```

**Drift Scenario:**
```bash
# Initial apply: All resources created correctly
terraform apply
# Resources created: 4 (VPC, Subnet, SG, EC2)

# Manual changes via console:
aws ec2 modify-instance-attribute \
  --instance-id i-1234567890 \
  --instance-type t3.large  # Changed from t3.medium!

aws ec2 authorize-security-group-ingress \
  --group-id sg-1234 \
  --protocol tcp --port 22 \
  --cidr 0.0.0.0/0  # SSH from anywhere! (Not in code)

aws ec2 create-tags --resources i-1234567890 \
  --tags Key=MaintainedBy,Value=ops-team  # Extra tag

# Detect drift:
terraform plan
# Output:
# ~ aws_instance.app
#   - instance_type: "t3.medium" -> "t3.large"  [DRIFT]
#   - tags {"MaintainedBy"}: <not shown> -> "ops-team"  [DRIFT]
#
# ~ aws_security_group.app
#   - ingress: Manual rule added (SSH) detected in actual  [DRIFT]

# Remediate:
terraform apply  # Reverts to code-specified state
# All drifted resources corrected
```

#### Example 2: Managing Drift with Lifecycle Rules

```hcl
resource "aws_security_group" "app" {
  name = "app-sg"
  vpc_id = aws_vpc.main.id

  # Allow inbound from load balancer
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }

  # AWS WAF might add rules automatically
  # These are acceptable and shouldn't be considered drift
  lifecycle {
    ignore_changes = [
      ingress  # Allow WAF to add rules without drift detection
    ]
  }
}

# Better: Use separate for managed and dynamic rules
resource "aws_security_group" "app" {
  name   = "app-sg"
  vpc_id = aws_vpc.main.id
}

resource "aws_security_group_rule" "app_from_alb" {
  type                     = "ingress"
  from_port                = 8080
  to_port                  = 8080
  protocol                 = "tcp"
  security_group_id        = aws_security_group.app.id
  source_security_group_id = aws_security_group.alb.id
}

# WAF can add its own rules without interfering with Terraform management
```

#### Example 3: CLI Commands for Drift Detection

```bash
# 1. Basic drift check
terraform plan
# Shows what WOULD change if applying
# Indicates any drift present

# 2. Detailed drift report
terraform plan -json > plan.json
jq '.resource_changes[] | select(.change.actions != ["no-op"])' plan.json
# Lists only resources with changes (drift)

# 3. Refresh state and compare
terraform refresh
terraform plan
# Ensures state is current with actual infrastructure

# 4. Check specific resource for drift
terraform state show aws_instance.app
# Shows current state (after refresh)
grep instance_type
# Compare to terraform show -json | jq to see actual

# 5. Full automated drift detection in CI/CD
terraform plan -out=tfplan -json | \
  jq -r '.resource_changes[] | 
          select(.change.actions | length > 0 and . != ["no-op"]) | 
          "Drift: \(.type).\(.name) \(.change.actions[0])"' \
  | tee drift_report.txt

# If report not empty, send alert
if [ -s drift_report.txt ]; then
  send_alert_to_slack < drift_report.txt
fi
```

### ASCII Diagrams

#### Diagram 1: Drift Creation Scenarios

```
Scenario 1: Manual Console Changes
┌──────────────────────────────────────────────┐
│ Terraform Code (Desired State)               │
│ resource "aws_instance" "app" {               │
│   instance_type = "t3.micro"                 │
│ }                                            │
└──────────────────────────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────┐
        │   terraform.tfstate      │
        │   instance_type: t3.micro│
        └──────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────┐
        │  AWS Console Change!     │
        │  Manual resize to        │
        │  t3.large               │
        └──────────────┬───────────┘
                       │
                       ▼
        ┌──────────────────────────┐
        │  AWS Reality             │
        │  instance_type: t3.large │  ◄─── DRIFT!
        └──────────────────────────┘
               (Code vs Reality)
                    t3.micro != t3.large


Scenario 2: Auto-Scaling Creates Instance
┌──────────────────────────────────────────────┐
│ Terraform Code (Desired State)               │
│ resource "aws_autoscaling_group" "app" {     │
│   desired_capacity = 2                       │
│   instances: [i-111, i-222]                  │
│ }                                            │
└──────────────────────────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────┐
        │   terraform.tfstate      │
        │   instances: [i-111,     │
        │               i-222]     │
        └──────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────┐
        │  AWS Auto-Scaling Action │
        │  High CPU triggers       │
        │  Scaling from 2→3        │
        └──────────────┬───────────┘
                       │
                       ▼
        ┌──────────────────────────┐
        │  AWS Reality             │
        │  instances: [i-111,      │
        │      i-222, i-333]       │  ◄─── DRIFT!
        └──────────────────────────┘
             (Code expects 2, Actual: 3)


Scenario 3: Manual Resource Creation (Orphan)
         ┌──────────────────────────┐
         │  Terraform Code          │
         │  (2 resources)           │
         └──────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────┐
        │   terraform.tfstate      │
        │   (2 resources)          │
        └──────────────────────────┘
                       │
                       ▼
        ┌──────────────────────────┐
        │  AWS Console             │
        │  Create 1 new resource   │
        │  (manual, not in TF)     │
        └──────────────┬───────────┘
                       │
                       ▼
        ┌──────────────────────────┐
        │  AWS Reality             │
        │  (3 resources)           │  ◄─── DRIFT!
        │  1 orphaned (not in TF)  │
        └──────────────────────────┘
```

#### Diagram 2: Drift Detection Workflow

```
Periodic Drift Check (Daily):

┌──────────────────────────────────────────┐
│  Scheduled Job (every 24 hours)          │
│  Execute: terraform plan                 │
└────────────┬─────────────────────────────┘
             │
      ┌──────┴──────┐
      │             │
      ▼             ▼
  ┌─────────┐  ┌──────────────────┐
  │ No Drift│  │ Drift Detected   │
  │         │  │                  │
  │ No action   │ Resource Changes │
  │         │  │ - Type X         │
  │ Log OK  │  │ - Attribute Y    │
  └─────────┘  │ - Tag Z          │
               └────────┬─────────┘
                        │
                  ┌─────┴──────┐
                  │            │
                  ▼            ▼
       ┌──────────────┐   ┌──────────────┐
       │ Auto-Fix OK? │   │ Requires     │
       │ (Low risk)   │   │ Review       │
       │              │   │ (Breaking)   │
       │ Execute:     │   │              │
       │  terraform   │   │ Create       │
       │  apply       │   │ Ticket:      │
       │              │   │ DriftAlert   │
       └──────────────┘   │              │
                          │ Notify Team  │
                          └──────────────┘
```

---

## Subtopic: Provisioning vs Configuration Management

### Textual Deep Dive

#### Architecture Role

Provisioning and Configuration Management are distinct but complementary infrastructure operations:

**Provisioning**: Creating and managing cloud infrastructure resources
- Creates compute instances (EC2, VMs)
- Creates networking (VPCs, load balancers)
- Creates storage (S3, databases)
- Manages resource lifecycle (creation, modification, deletion)
- Technology: **Terraform, CloudFormation, ARM templates**

**Configuration Management**: Applying and maintaining software configuration on existing systems
- Installs packages and software
- Manages file contents and permissions
- Configures services and applications
- Manages system state (users, groups, services)
- Technology: **Ansible, Chef, Puppet, Salt**

**Distinction:**

| Aspect | Provisioning | Configuration Management |
|--------|--------------|------------------------|
| **Scope** | Infrastructure layers | Application/OS layers |
| **Frequency** | Infrequent (infrastructure rarely changes) | Frequent (application config updates) |
| **State Management** | Terraform state (fine-grained) | Idempotent scripts (convergence) |
| **Speed** | Minutes to hours | Seconds to minutes |
| **Tooling** | Infrastructure-specific (AWS, Azure) | OS-agnostic (works across clouds) |
| **Problem Domain** | "How do I create a VPC?" | "How do I configure Nginx?" |

#### Internal Working Mechanism

**Traditional Approach (Separated Concerns):**

```
Developer Workflow:

1. PROVISIONING (Day 1)
   └─ Write Terraform code
     └─ Define: VPC, Subnet, Security Groups, EC2, RDS, etc.
     └─ terraform apply
     └─ Result: Bare infrastructure exists

2. CONFIGURATION (Post-provisioning)
   └─ Login to instances
   └─ Or use Configuration Management tool (Ansible)
     └─ Install packages: apt-get install nginx
     └─ Copy config files
     └─ Start services
     └─ Result: Infrastructure is ready for application

3. APPLICATION DEPLOYMENT
   └─ Deploy application code
   └─ Start application services
   └─ Result: Application runs
```

**Modern Approach (Unified with User Data):**

```
Developer Workflow:

Provisioning includes configuration:
   └─ Terraform defines:
     ├─ Infrastructure (VPC, Security Groups, EC2)
     └─ Initial configuration (via user_data script)
   └─ EC2 user_data script:
     ├─ Install packages
     ├─ Copy configuration files
     ├─ Start services
   └─ terraform apply does both:
     ├─ Creates infrastructure
     ├─ Configures upon startup
   └─ Result: Infrastructure is ready immediately
```

**Comparison of Architectures:**

```
OLD APPROACH (Separate):

Terraform Configuration:
┌────────────────────────────┐
│ resource "aws_instance" {  │
│   ami = "ami-base"        │
│   # No configuration      │
│ }                          │
└────────────────────────────┘
            │
            ▼ (infrastructure only)
         Bare EC2
            │
            ▼
Ansible Playbook:
┌────────────────────────────┐
│ - name: Install Nginx      │
│   apt: name=nginx          │
│ - name: Configure          │
│   copy: src=nginx.conf     │
│ - name: Start service      │
│   service: name=nginx      │
└────────────────────────────┘
            │
            ▼ (apply configuration)
       Configured EC2

Problems:
- Provisioning and config are decoupled
- Manual steps between provisioning and config
- Ansible must connect to instance (requires network setup)
- Configuration drift between runs
- Two different state systems (Terraform + Ansible inventory)


MODERN APPROACH (Unified):

Terraform Configuration:
┌────────────────────────────┐
│ resource "aws_instance" {  │
│   ami = "ami-base"        │
│   user_data = base64encode(│
│     file("init.sh")        │
│   )                        │
│ }                          │
└────────────────────────────┘
            │
            ├─ Provision: Create EC2
            │
            └─ Configure: Run user_data script
                ├─ Install packages
                ├─ Copy files
                └─ Start services
            │
            ▼
      Configured EC2 (immediate)

Advantages:
- Single source of truth (Terraform code)
- Infrastructure and config are atomic (both or neither)
- No additional tools needed
- Faster deployment (no separate config runs)
- Single state system (Terraform)
```

#### Production Usage Patterns

**Pattern 1: Lightweight Configuration (Terraform User Data)**

Simple infrastructure that doesn't require complex configuration:

```hcl
resource "aws_instance" "api_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t3.medium"

  user_data = base64encode(templatefile("${path.module}/init.sh", {
    environment = var.environment
    db_host     = aws_rds_cluster.main.endpoint
    api_port    = 8080
  }))

  tags = {
    Name = "api-server"
  }
}
```

User data script (init.sh):
```bash
#!/bin/bash
set -e

# Update system
apt-get update && apt-get upgrade -y

# Install runtime
apt-get install -y python3 python3-pip

# Install application dependencies
pip3 install Flask==2.0.1 psycopg2==2.9.1

# Create application directory
mkdir -p /opt/api

# Configuration via environment
echo "API_PORT=${api_port}" >> /opt/api/.env
echo "DB_HOST=${db_host}" >> /opt/api/.env
echo "ENVIRONMENT=${environment}" >> /opt/api/.env

# Start application
systemctl start api-server
```

**Pattern 2: Container-Based Configuration**

Complex infrastructure using Kubernetes or ECS:

```hcl
# Provisioning: Create ECS cluster
resource "aws_ecs_cluster" "main" {
  name = "production-cluster"
}

# Provisioning: Create task definition (configuration as code)
resource "aws_ecs_task_definition" "api" {
  family       = "api-task"
  cpu          = "256"
  memory       = "512"
  network_mode = "awsvpc"

  container_definitions = jsonencode([{
    name      = "api"
    image     = "${aws_ecr_repository.api.repository_url}:latest"
    portMappings = [{
      containerPort = 8080
      hostPort      = 8080
      protocol      = "tcp"
    }]
    environment = [
      {
        name  = "DATABASE_URL"
        value = "postgresql://user:pass@${aws_rds_cluster.main.endpoint}:5432/db"
      },
      {
        name  = "ENVIRONMENT"
        value = var.environment
      }
    ]
  }])
}

# Provisioning: Create ECS service
resource "aws_ecs_service" "api" {
  name            = "api-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.api.arn
  desired_count   = 3
  launch_type     = "FARGATE"
}
```

Configuration is **embedded in container images** (built outside Terraform):
```dockerfile
FROM python:3.11-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install -r requirements.txt
COPY . .
CMD ["python", "app.py"]  # Configuration via environment variables
```

**Pattern 3: Hybrid Provisioning + Configuration Management**

Complex infrastructure requiring both tools:

```hcl
# Terraform: Provision infrastructure
resource "aws_instance" "jenkins_master" {
  ami           = "ami-base"
  instance_type = "t3.large"
  key_name      = aws_key_pair.jenkins.key_name

  user_data = base64encode(file("${path.module}/bootstrap.sh"))

  tags = {
    Name = "jenkins-master"
  }
}

# bootstrap.sh: Basic setup only
#!/bin/bash
java -version  # Install Java
apt-get install -y docker.io
```

Then Ansible handles complex configuration:
```yaml
# ansible/site.yml
- hosts: jenkins_master
  tasks:
    - name: Configure Jenkins
      jenkins_plugin:
        name: "{{ item }}"
      loop:
        - kubernetes
        - pipeline
        - git
    
    - name: Configure Jenkins security
      jenkins_credentials:
        credentials: "{{ vault_credentials }}"
    
    - name: Create build agents
      template:
        src: agent-config.j2
        dest: /var/lib/jenkins/agent-{{ item }}.xml
      loop: "{{ build_agents }}"
```

**Pattern 4: Immutable Infrastructure (Best Practice)**

Configuration baked into images, not applied to running instances:

```hcl
# Provisioning: Build image with Packer
resource "null_resource" "build_ami" {
  provisioner "local-exec" {
    command = "packer build -var 'version=${var.app_version}' packer.json"
  }
}

data "aws_ami" "app" {
  most_recent = true
  filter {
    name   = "tag:application"
    values = ["myapp"]
  }
  filter {
    name   = "tag:version"
    values = [var.app_version]
  }
}

# Provisioning: Launch instances with pre-configured image
resource "aws_instance" "app_servers" {
  count         = 3
  ami           = data.aws_ami.app.id  # Configuration in image
  instance_type = "t3.medium"
  # NO user_data (configuration already in AMI)
}
```

Packer configuration:
```hcl
# packer.json
{
  "builders": [{
    "type": "amazon-ebs",
    "ami_name": "myapp-{{var.version}}",
    "instance_type": "t3.large",
    "source_ami": "ami-base"
  }],
  "provisioners": [
    {
      "type": "shell",
      "script": "install-dependencies.sh"
    },
    {
      "type": "ansible",
      "playbook_file": "playbook.yml"
    }
  ]
}
```

#### DevOps Best Practices

1. **Use User Data for Simple Configuration**
   - Scripting language: Bash, Python, PowerShell
   - Use cases: Package installation, basic service setup
   - Limit to <1000 lines of code
   - Clear and maintainable scripts

2. **Use Configuration Management for Complex Setup**
   - When user_data exceeds complexity threshold
   - When idempotency is critical
   - When configuration requires extensive testing
   - When managing 100+ hosts

3. **Prefer Containers Over Host Configuration**
   - Configuration embedded in container images
   - Eliminates configuration drift on hosts
   - Portable across cloud providers
   - Simpler scaling and updates

4. **Immutable Infrastructure First**
   - Bake configuration into images (AMI, Docker)
   - Replace instances instead of modifying
   - Eliminates configuration drift
   - Faster deployments

5. **Separate Concerns Clearly**
   - Provisioning: Infrastructure (Terraform)
   - Configuration: Application/OS (Chef, Ansible, Packer)
   - Deployment: Application code (GitOps, CI/CD)

6. **Use Template Files for Complex Configuration**
   ```hcl
   user_data = base64encode(templatefile("${path.module}/init.sh", {
     domain_name = var.domain
     db_host     = aws_db_instance.main.address
     api_key     = random_password.api_key.result
   }))
   ```

7. **Maintain Idempotency in Configuration Scripts**
   ```bash
   # IDEMPOTENT: Checks if already done
   if ! grep -q "domain=${domain_name}" /etc/config; then
     echo "domain=${domain_name}" >> /etc/config
   fi
   
   # Enable service (safe to run multiple times)
   systemctl enable nginx
   ```

#### Common Pitfalls

**Pitfall 1: Mixing Provisioning and Configuration**

```hcl
# WRONG: Using provisioners for everything
resource "aws_instance" "web" {
  ami = "ami-base"
  
  provisioner "remote-exec" {
    inline = [
      "apt-get update",
      "apt-get install nginx",
      "nginx -g 'daemon off;'"  # Configuration
    ]
  }
}

# WRONG: Using Terraform to manage application code
resource "aws_instance" "app" {
  provisioner "file" {
    source      = "app-v1.tar.gz"
    destination = "/tmp/app.tar.gz"
  }
}

# CORRECT: Separate roles
# Terraform: Define infrastructure only
resource "aws_instance" "web" {
  ami       = data.aws_ami.web.id  # Pre-configured image
  user_data = base64encode(file("init.sh"))  # Lightweight setup
}

# Separate: Ansible/Chef manages complex configuration
# Separate: CI/CD deploys application code
```

**Pitfall 2: Not Idempotent Configuration Scripts**

```bash
# WRONG: Non-idempotent (runs differently each time)
#!/bin/bash
echo "Starting setup"
node=1
for i in range(1, 5); do
  create_node $node  # Fails if node already exists
  node=$((node + 1))
done

# CORRECT: Idempotent (safe to run multiple times)
#!/bin/bash
for i in {1..4}; do
  if ! node_exists "node-$i"; then
    create_node "node-$i"
  fi
done
```

**Pitfall 3: Provisioners with Configuration Management**

```hcl
# WRONG: Mixing provisioners with Terraform
resource "aws_instance" "app" {
  ami = "ami-base"
  
  provisioner "local-exec" {
    command = "ansible-playbook -i ${self.private_ip}, site.yml"
  }
  # Problems:
  # - Provisioner runs outside Terraform's control
  # - Difficult to debug
  # - Mixes two state systems
}

# BETTER: Use Terraform + separate Ansible inventory
resource "aws_instance" "app" {
  ami = "ami-base"
}

# Generate Ansible inventory separately
resource "local_file" "ansible_inventory" {
  content = "[app]\n${aws_instance.app.private_ip}"
}

# Run Ansible in CI/CD pipeline, not Terraform
```

**Pitfall 4: Over-Complex User Data Scripts**

```bash
# WRONG: 2000+ lines of bash
user_data = base64encode(file("huge-script.sh"))  # unmaintainable

# CORRECT: Use Packer for pre-built images
# OR: Use lightweight init, complex setup in containers/config management
user_data = base64encode(file("lightweight-init.sh"))  # <100 lines
```

**Pitfall 5: Treating Configuration as Code is Different from IaC**

```hcl
# WRONG: Assuming Terraform can manage all configuration
# Configure application via Terraform (doesn't work well)

# CORRECT: Recognize boundaries
# Terraform: Infrastructure (what exists)
# Configuration Management: How it's configured (Ansible, Chef, Puppet)
# Application Deployment: What runs (CI/CD, GitOps)
```

### Practical Code Examples

#### Example 1: Complete Provisioning + Configuration Stack

```hcl
# main.tf: Provision infrastructure
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "app" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
}

resource "aws_security_group" "app" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_cidr]
  }
}

resource "aws_instance" "app" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.medium"
  subnet_id                   = aws_subnet.app.id
  vpc_security_group_ids      = [aws_security_group.app.id]
  associate_public_ip_address = true

  # Provisioning: Basic setup
  user_data = base64encode(templatefile("${path.module}/init.sh", {
    environment = var.environment
    region      = var.aws_region
  }))

  tags = {
    Name = "app-server"
  }

  depends_on = [aws_internet_gateway.main]  # Provisioning dependency
}

output "app_server_ip" {
  value = aws_instance.app.public_ip
}
```

init.sh (Provisioning script - basic setup only):
```bash
#!/bin/bash
set -e

# Update system
apt-get update
apt-get upgrade -y

# Install minimal runtime
apt-get install -y python3 python3-pip curl

# Create app user
useradd -m -s /bin/bash appuser

# Create app directory
mkdir -p /opt/myapp
chown appuser:appuser /opt/myapp

# Install basic monitoring agent
apt-get install -y cloudwatch-agent

# Signal completion (systemd or custom)
echo "Provisioning complete" > /var/log/provisioning.log
```

Then Ansible (Configuration Management) handles:
```yaml
---
- hosts: app_servers
  become: yes
  tasks:
    - name: Install application dependencies
      apt:
        name: "{{ item }}"
        state: present
      loop:
        - nodejs
        - npm
        - postgresql-client
    
    - name: Clone application repository
      git:
        repo: "{{ app_repo }}"
        dest: /opt/myapp
        version: "{{ app_version }}"
      become_user: appuser
    
    - name: Install npm packages
      npm:
        path: /opt/myapp
      become_user: appuser
    
    - name: Configure environment
      template:
        src: app.env.j2
        dest: /opt/myapp/.env
        owner: appuser
        group: appuser
        mode: '0600'
    
    - name: Start application service
      systemd:
        name: myapp
        enabled: yes
        state: started
```

#### Example 2: Immutable Infrastructure with Packer

```json
// packer.json
{
  "variables": {
    "version": "1.0.0",
    "app_env": "production"
  },
  "builders": [{
    "type": "amazon-ebs",
    "region": "us-east-1",
    "source_ami_filter": {
      "filters": {
        "name": "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*",
        "root-device-type": "ebs"
      },
      "owners": ["099720109477"],
      "most_recent": true
    },
    "instance_type": "t3.large",
    "ami_name": "myapp-{{user `version`}}",
    "tags": {
      "Name": "myapp",
      "Version": "{{user `version`}}",
      "Environment": "{{user `app_env`}}"
    }
  }],
  "provisioners": [
    {
      "type": "shell",
      "inline": [
        "apt-get update",
        "apt-get install -y build-essential python3 python3-pip"
      ]
    },
    {
      "type": "file",
      "source": "./app",
      "destination": "/tmp/app"
    },
    {
      "type": "ansible",
      "playbook_file": "./ansible/build.yml",
      "extra_arguments": [
        "-e", "app_version={{user `version`}}"
      ]
    },
    {
      "type": "shell",
      "inline": [
        "rm -rf /tmp/app",
        "apt-get clean"
      ]
    }
  ]
}
```

Terraform uses pre-built image:
```hcl
data "aws_ami" "myapp" {
  most_recent = true
  owners      = ["self"]
  filter {
    name   = "name"
    values = ["myapp-*"]
  }
  filter {
    name   = "tag:Version"
    values = [var.app_version]
  }
}

resource "aws_launch_template" "myapp" {
  image_id      = data.aws_ami.myapp.id  # Pre-configured!
  instance_type = "t3.medium"
  # No user_data! Configuration is in the image
}
```

#### Example 3: CLI Commands for Provisioning vs Configuration

```bash
# 1. Provisioning (Terraform)
terraform plan
# Shows infrastructure changes (EC2, VPC, RDS, etc.)

terraform apply
# Creates infrastructure on cloud providers

# 2. Light Configuration (via user_data, embedded in provisioning)
# Happens automatically when EC2 starts
# Logs available at: /var/log/cloud-init-output.log

# 3. Complex Configuration (Ansible, separate from provisioning)
ansible-playbook site.yml -i inventory.ini
# Configures running instances
# Idempotent (can run multiple times)

# 4. Immutable Approach (Packer builds image first)
packer build packer.json
# Builds AMI with all configuration baked in

terraform apply
# Provisions using pre-built image (no post-provisioning config needed)

# 5. Verify final state
terraform show | grep instance_type
ansible-playbook verify.yml  # Verify configuration applied
```

### ASCII Diagrams

#### Diagram 1: Provisioning vs Configuration Workflow

```
TRADITIONAL APPROACH (Separated):

┌─────────────────────────────────────────────────────────────┐
│                    Day 1: Provisioning                       │
│                                                              │
│  Engineer writes: main.tf                                   │
│  resource "aws_instance" "web" {                             │
│    ami = "ami-base"   # No configuration                    │
│  }                                                           │
│                                                              │
│  terraform apply                                            │
│         │                                                   │
│         ▼                                                   │
│  AWS: EC2 instance created, running base OS                 │
│  Status: ✓ Infrastructure ready                             │
│  Status: ✗ Not usable yet (no applications)                 │
└─────────────────────────────────────────────────────────────┘
                           │
                           │ MANUAL STEP
                           ▼
┌─────────────────────────────────────────────────────────────┐
│              Day 2: Configuration Management                │
│                                                              │
│  Engineer writes: site.yml                                  │
│  - name: Install Nginx                                      │
│    apt: name=nginx                                          │
│  - name: configure Nginx                                    │
│    copy: ...                                                │
│                                                              │
│  ansible-playbook site.yml -i inventory.ini                 │
│         │                                                   │
│         ▼                                                   │
│  Ansible connects to EC2, applies configuration             │
│  Status: ✓ Applications installed and configured            │
└─────────────────────────────────────────────────────────────┘

Problems:
- Two separate steps
- Manual coordination
- Failure points between step 1 and 2
- Multiple state systems


MODERN APPROACH (Integrated with User Data):

┌─────────────────────────────────────────────────────────────┐
│               Day 1: Provisioning + Configuration            │
│                                                              │
│  Engineer writes: main.tf                                   │
│  resource "aws_instance" "web" {                             │
│    ami = "ami-base"                                         │
│    user_data = base64encode(file("init.sh"))               │
│  }                                                           │
│                                                              │
│  terraform apply                                            │
│         │                                                   │
│         ├─> AWS: Create EC2 instance                        │
│         │                                                   │
│         └─> EC2 Startup: Execute user_data script          │
│             ├─ apt-get update                               │
│             ├─ apt-get install nginx                        │
│             ├─ copy config files                            │
│             └─ systemctl start nginx                        │
│         │                                                   │
│         ▼                                                   │
│  EC2 instance ready with applications                       │
│  Status: ✓ Infrastructure + Configuration complete         │
└─────────────────────────────────────────────────────────────┘

Advantages:
- Single terraform apply does it all
- No manual steps
- Atomic operation (both or neither)
- Single state system


IMMUTABLE APPROACH (Packer):

┌─────────────────────────────────────────────────────────────┐
│         Pre-Deployment: Build Image (Packer)               │
│                                                              │
│  cd infrastructure/packer                                   │
│  packer build -var "version=1.0.0" packer.json             │
│         │                                                   │
│         ├─> Provision EC2 builder instance                 │
│         │                                                   │
│         ├─> Apply configuration (shell, Ansible)           │
│         │   ├─ Install all packages                        │
│         │   ├─ Apply all configuration                     │
│         │   └─ Start all services                          │
│         │                                                   │
│         ├─> Create AMI snapshot                            │
│         │                                                   │
│         └─> Tag as: myapp-1.0.0                            │
│                                                              │
│  Output: Custom AMI with everything pre-configured         │
└─────────────────────────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│          Production: Launch from Pre-Built Image            │
│                                                              │
│  resource "aws_instance" "web" {                             │
│    ami = data.aws_ami.myapp.id  # Pre-configured image     │
│  }                                                           │
│                                                              │
│  terraform apply                                            │
│         │                                                   │
│         ├─> AWS: Launch EC2 from AMI                       │
│         │                                                   │
│         └─> EC2 Startup: Everything already configured     │
│             (no additional setup needed)                    │
│         │                                                   │
│         ▼                                                   │
│  EC2 instantly ready (no waiting for config)               │
│  Status: ✓ Fast deployment, zero configuration drift       │
└─────────────────────────────────────────────────────────────┘

Advantages:
- Fastest deployments
- Zero post-launch configuration
- No configuration drift on running instances
- Tested configuration (built once, deployed many times)
```

#### Diagram 2: Decision Tree for Tool Selection

```
When configuring infrastructure, ask:

                ┌─ Is it infrastructure?
                │ (VPC, EC2, RDS, Security Groups)
                │ YES → Use TERRAFORM
                │
        Does the task involve:
        creating or modifying
        cloud resources?      NO → Not infrastructure provisioning
                │
                └─ Is it OS/Application configuration?
                  (Install packages, edit config files, start services)
                  YES → Ask next question
                        │
                        ├─ Complexity: Simple (<200 lines)?
                        │ YES → Use Terraform user_data
                        │
                        ├─ Complexity: Moderate (200-1000 lines)?
                        │ YES → Use Terraform + lightweight provisioner
                        │
                        ├─ Complexity: High (>1000 lines, many steps)?
                        │ YES → Use Packer (build image) or
                        │       Configuration Management (Ansible/Chef)
                        │
                        ├─ Idempotency critical (must run multiple times)?
                        │ YES → Use Ansible/Chef (built-in idempotency)
                        │
                        └─ Managing 100+ hosts or complex orchestration?
                          YES → Use Kubernetes or Ansible
                                (declarative, scalable)


FINAL DECISION MATRIX:

┌────────────────────┬──────────────┬──────────────┬─────────────┐
│ Scenario           │ Provisioning │ Configuration│ Deployment  │
├────────────────────┼──────────────┼──────────────┼─────────────┤
│ Static App Server  │ Terraform    │ User Data    │ CI/CD       │
│ Kubernetes Cluster │ Terraform    │ User Data    │ kubectl     │
│ Complex Enterprise │ Terraform    │ Packer+Ansi │ GitOps      │
│ Microservices      │ Terraform    │ Containers  │ Kubernetes  │
│ Database Server    │ Terraform    │ Ansible     │ N/A         │
│ Build Agent Farm   │ Terraform    │ Packer      │ CI/CD       │
└────────────────────┴──────────────┴──────────────┴─────────────┘
```

## Hands-on Scenarios

### Scenario 1: Detecting and Remediating Drift in a Multi-Tier Production Stack

#### Problem Statement

Your organization manages a production Kubernetes cluster on AWS provisioned via Terraform. On Monday morning, you receive alert: "RDS master user password is not matching expected value." Upon investigation, you discover:

- System admin manually rotated RDS password via AWS console (emergency security measure)
- Load balancer security group has extra ingress rule (port 22 from 0.0.0.0/0, likely added for debugging)
- Auto-scaling group desired_capacity is 5 instead of 3 (someone scaled up during a "spike")
- Three custom tags were added to EC2 instances not present in Terraform code
- VPC flow logs configuration changed (modified via console)

**Business Context**: Production system serving 10,000 users. Changes made last Friday, discovered Monday. Unknown who made changes and when exactly.

#### Architecture Context

```
Production Stack:
┌─────────────────────────────────────────┐
│  Load Balancer (ALB)                    │
│  - Security Group (6 ingress rules)     │
│  - Target Groups (3)                    │
└──────────────────┬──────────────────────┘
                   │
        ┌──────────┼──────────┐
        │          │          │
     ┌──▼──┐   ┌──▼──┐   ┌──▼──┐
     │ EC2 │   │ EC2 │   │ EC2 │  (desired_capacity=3, actual=5)
     │ Pod1│   │ Pod2│   │ Pod3│  ← ASG with auto-scaling enabled
     └──┬──┘   └──┬──┘   └──┬──┘
        │          │          │
     ┌──▼──────────▼──────────▼──┐
     │    RDS Aurora Cluster      │
     │  - Master User: admin      │
     │  - Password: ????          │  ← Password manually changed
     │  - Backup: 30 days         │
     └────────────────────────────┘
```

#### Step-by-Step Troubleshooting & Implementation

**Step 1: Detect Drift (Monday Morning)**

```bash
cd /infrastructure/prod

# Initial detection
terraform plan
# Output shows numerous diffs:
# ~ aws_security_group.alb_sg
# - ingress: [old rules] -> [old rules + extra SSH rule]
#
# ~ aws_autoscaling_group.eks_nodes  
# - desired_capacity: 3 -> 5
#
# ! aws_rds_cluster.main
# - master_password: <hidden> (can't compare encrypted)
#
# ~ aws_instance.app[0]
# ~ aws_instance.app[1]
# ~ aws_instance.app[2]
# - tags: [missing tags]

# Detailed drift report with JSON
terraform plan -json | \
  jq '.resource_changes[] | select(.change.actions != ["no-op"]) | 
      {resource: .address, changes: .change.actions}' | tee drift_report.json
```

**Step 2: Investigate Root Cause (Forensics)**

```bash
# Check who made changes (AWS CloudTrail)
aws logs filter-log-events \
  --log-group-name CloudTrail \
  --filter-pattern "ModifyDBCluster OR ModifySecurityGroup OR PutScalingPolicy" \
  --start-time $(date -d 'Friday 12:00' +%s)000 \
  --end-time $(date -d 'Monday 6:00' +%s)000 \
  --query 'events[*].{User:userIdentity.principalId,Action:eventName,Time:eventTime}'

# Output example:
# User: alice@company.com
# Action: ModifyDBCluster
# Reason: Emergency security response - credential rotation

# Check ASG scaling history
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name prod-eks-nodes \
  --start-time $(date -d 'Friday 12:00' +%s) \
  --max-records 50

# Output: Friday 3:00 PM - Scaling event triggered (high CPU)
```

**Step 3: Categorize Drift (Intentional vs Accidental)**

```
Drift Assessment:

1. RDS Password Change
   ├─ Type: INTENTIONAL
   ├─ Risk Level: HIGH (breaks Terraform state)
   ├─ Cause: Emergency security rotation
   └─ Action: Update Terraform code

2. Security Group Extra SSH Rule
   ├─ Type: ACCIDENTAL
   ├─ Risk Level: CRITICAL (security violation)
   ├─ Cause: Debugging access added, forgotten
   └─ Action: Remove immediately via Terraform

3. ASG Desired Capacity Increase
   ├─ Type: INTENTIONAL (with downstream effects)
   ├─ Risk Level: MEDIUM (cost impact, not security)
   ├─ Cause: Manual scaling during traffic spike
   └─ Action: Evaluate if sustained increase needed

4. EC2 Instance Tags
   ├─ Type: ACCIDENTAL
   ├─ Risk Level: LOW (operational, not functional)
   ├─ Cause: Tagging for cost allocation added manually
   └─ Action: Add to Terraform code

5. VPC Flow Logs Configuration
   ├─ Type: INTENTIONAL
   ├─ Risk Level: LOW (visibility improvement)
   ├─ Cause: Enable for incident investigation
   └─ Action: Update Terraform code
```

**Step 4: Resolve Critical Drift (Security Group)**

```hcl
# Current code (outdated):
resource "aws_security_group" "alb_sg" {
  name = "prod-alb-sg"
  
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Missing: Unwanted SSH rule in actual state
}

# Resolution: Use aws_security_group_rule instead (better for drift)
resource "aws_security_group" "alb_sg" {
  name = "prod-alb-sg"
  vpc_id = aws_vpc.main.id
  
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  tags = local.common_tags
}

# Define rules explicitly
resource "aws_security_group_rule" "alb_https" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_security_group_rule" "alb_http" {
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

# Benefits: Terraform now detects ANY extra rules and removes them
```

**Step 5: Resolve RDS Password Drift (Non-Idempotent)**

```hcl
# PROBLEMATIC CODE:
resource "aws_rds_cluster" "main" {
  cluster_identifier = "prod-db"
  master_username    = "admin"
  master_password    = random_password.db_password.result
  # Problem: random_password regenerates on every apply!
}

resource "random_password" "db_password" {
  length  = 32
  special = true
}

# First apply: Creates password
# Second apply: Generates NEW password, tries to update RDS
# Result: Non-idempotent, causes unintended changes

# SOLUTION 1: Use AWS Secrets Manager
resource "aws_secretsmanager_secret" "db_password" {
  name_prefix = "rds-master-password-"
}

resource "random_password" "db_password" {
  length  = 32
  special = true
}

resource "aws_secretsmanager_secret_version" "db_password" {
  secret_id      = aws_secretsmanager_secret.db_password.id
  secret_string  = random_password.db_password.result
  # Generated only on first apply, subsequent applies reference stored value
}

resource "aws_rds_cluster" "main" {
  cluster_identifier = "prod-db"
  master_username    = "admin"
  master_password    = var.rds_master_password  # From vars/environment
  # Password managed outside Terraform state
  
  lifecycle {
    ignore_changes = [master_password]  # Don't update if externally changed
  }
}

# SOLUTION 2: Sync password from manual change
terraform import aws_secretsmanager_secret.db_password arn:aws:secretsmanager:...
# Update code to match actual password setup
```

**Step 6: Address ASG Scaling Decision**

```bash
# Analyze whether increased capacity should be permanent
aws cloudwatch get-metric-statistics \
  --namespace AWS/ECS \
  --metric-name CPUUtilization \
  --dimensions Name=ClusterName,Value=prod-eks \
  --start-time $(date -u -d '7 days ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Average,Maximum

# Analysis: High CPU spike Friday 3-5 PM, back to normal by Saturday
# Decision: Revert to desired_capacity = 3 (temporary spike, not sustained)

terraform plan  # Shows ASG will reduce by 2 instances

# BUT: Use lifecycle to avoid disruption
resource "aws_autoscaling_group" "eks_nodes" {
  desired_capacity = 3  # Revert to code-specified
  
  lifecycle {
    create_before_destroy = true  # Gradual replacement, not sudden termination
  }
}

terraform apply  # Gradually terminates 2 ExtraInstances
```

**Step 7: Apply Comprehensive Fix**

```bash
# Review complete plan
terraform plan -out=prod_remediation.tfplan

# Expected output:
# - aws_security_group_rule.unwanted_ssh: Removal
# - aws_autoscaling_group.eks_nodes: desired_capacity 5 -> 3
# - aws_instance.app[0-2]: tags updated
# - aws_rds_cluster.main: ignore_changes lifecycle added
# + aws_secretsmanager_secret.*: New resources for password management

# Approval process (critical for production)
echo "Drift remediation plan created. Awaiting approval..."
echo "Changes:"
terraform show prod_remediation.tfplan | grep -E '^.*will|^.*must'

# Get approvals from:
# 1. Security team: SSH rule removal
# 2. Platform team: ASG capacity reduction
# 3. Database team: Password management change

# Apply
terraform apply prod_remediation.tfplan

# Verify
terraform plan  # Should show "No changes"
aws autoscaling describe-auto-scaling-groups \
  --auto-scaling-group-names prod-eks-nodes \
  --query 'AutoScalingGroups[0].DesiredCapacity'
# Output: 3
```

#### Best Practices Demonstrated

1. **Automated Drift Detection**
   - Regular `terraform plan` runs (CI/CD pipeline)
   - Drift alerts when changes detected

2. **Forensic Investigation**
   - CloudTrail auditing of all changes
   - Root cause categorization

3. **Layered Resolution**
   - Address critical security issues first (SSH rule)
   - Handle non-idempotent resources specially (RDS password)
   - Make informed decisions on intentional changes (ASG)

4. **Safe Remediation**
   - Use `ignore_changes` for externally-managed fields
   - Use `create_before_destroy` for graceful updates
   - Require approvals for significant changes

5. **Prevention**
   - Use fine-grained security group rules (aws_security_group_rule)
   - Externalize sensitive values (Secrets Manager)
   - Enable S3 object lock on remote state

---

### Scenario 2: Implementing Immutable Infrastructure for Zero-Downtime Deployments

#### Problem Statement

Your team currently uses Terraform to provision EC2 instances with `user_data` for application setup. During deployments, configuration changes temporarily cause service disruption. Database schema changes require 30+ seconds of application restart. You need:

- Zero-downtime deployments
- Instant rollback capability
- Tested configuration before production deployment
- Separate application code version from infrastructure

**Constraint**: 1000+ daily users with SLA of 99.99% uptime.

#### Architecture Context

```
Current (Problematic) Approach:

┌─────────────────┐       ┌──────────────────┐      ┌──────────────┐
│ Terraform Code  │──────▶│ EC2 Instance     │─────▶│ Running App  │
│ (v2 of app)     │       │ (user_data runs) │      │ (downtime!)  │
└─────────────────┘       └──────────────────┘      └──────────────┘
        │                           │                       │
        │                           └───────────────────────┘
        │                          Seconds of downtime
        │
        └──▶ Desired: user_data applies changes
            Problem: If changes fail, instance broken
            Problem: 30+ second apply time = 30 seconds of downtime

Desired Immutable Approach:

┌───────────────────────────────────────────────────────────────┐
│ Build Stage (EC2 Builder Instance)                           │
│  ┌──────────────┐       ┌──────────────┐                      │
│  │ Code Commit  │──────▶│ Packer Build │──────┐               │
│  │ (app v3)     │       │ - Install    │      │               │
│  │              │       │ - Configure  │      │               │
│  │              │       │ - Test       │      │               │
│  └──────────────┘       └──────────────┘      │               │
│                                   │            │               │
│                                   ▼            │               │
│                        Create AMI snapshot     │               │
│                        Tag: app-v3-validated   │               │
└───────────────────────────────────┬─────────────┘               │
                                    │                             │
                                    ▼                             │
                        ┌──────────────────────┐                 │
                        │ Push to ECR Registry │                 │
                        │  app:v3 (immutable)  │                 │
                        └──────────────────────┘                 │
                                    │                             │
                ┌───────────────────┴────────────────────┐       │
                │                                        │       │
        ┌───────▼──────┐               ┌──────────▼─────┐      │
        │ Staging Env  │               │ Production Env │      │
        │ (Canary Test)│               │ (Blue-Green)   │      │
        └───────┬──────┘               └────────────────┘      │
                │                                  │             │
                │ 1. Deploy v3 alongside v2       │             │
                │    (Load Balancer routes to v2) │             │
                │ 2. Run smoke tests              │             │
                │ 3. Gradually shift traffic      │             │
                │ 4. If OK: Complete cutover     │             │
                │ 5. If fail: Instant rollback    │             │
                │    (LB routes back to v2)      │             │
                ▼                                  ▼             │
        ┌──────────────┐               ┌────────────────┐      │
        │ v3 validated │               │ Zero downtime! │      │
        │ (can promote) │               │ (instant switch)      │
        └──────────────┘               └────────────────┘      │
```

#### Step-by-Step Implementation

**Step 1: Create Packer Template for Immutable Images**

```json
// packer.json
{
  "variables": {
    "app_version": "3.0.0",
    "aws_region": "us-east-1"
  },
  "builders": [{
    "type": "amazon-ebs",
    "region": "{{user `aws_region`}}",
    "source_ami_filter": {
      "filters": {
        "name": "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"
      },
      "owners": ["099720109477"],
      "most_recent": true
    },
    "instance_type": "t3.large",
    "ami_name": "app-{{user `app_version`}}",
    "tags": {
      "Name": "app-immutable",
      "Version": "{{user `app_version`}}",
      "BuildDate": "{{isotime `2006-01-02T15:04:05Z`}}",
      "ManagedBy": "Packer"
    },
    "encrypt_boot": true,
    "ebs_optimized": true
  }],
  "provisioners": [
    {
      "type": "file",
      "source": "./build",
      "destination": "/tmp/build"
    },
    {
      "type": "shell",
      "scripts": [
        "./scripts/install-dependencies.sh",
        "./scripts/harden-security.sh"
      ]
    },
    {
      "type": "ansible",
      "playbook_file": "./ansible/site.yml",
      "extra_arguments": [
        "-e", "app_version={{user `app_version`}}",
        "-e", "ansible_python_interpreter=/usr/bin/python3"
      ]
    },
    {
      "type": "shell",
      "inline": [
        "echo 'Running application tests...",
        "/opt/app/tests/smoke-test.sh",
        "echo 'Image successfully built and tested'"
      ]
    },
    {
      "type": "shell",
      "inline": ["history -c", "cat /dev/null > ~/.bash_history"]  // Clean logs
    }
  ]
}
```

**Step 2: Build and Test Image**

```bash
# In CI/CD pipeline (GitHub Actions example)
name: Build Immutable Image
on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Extract version from tag
        id: version
        run: echo "::set-output name=version::${GITHUB_REF#refs/tags/v}"
      
      - name: Build AMI with Packer
        env:
          AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        run: |
          packer build \
            -var "app_version=${{ steps.version.outputs.version }}" \
            packer.json
      
      - name: Tag image for ECR
        run: |
          aws ecr get-login-password --region us-east-1 | \
            docker login --username AWS --password-stdin ${{ secrets.ECR_REGISTRY }}
          
          # Also tag in Docker if using containers
          docker build -t app:${{ steps.version.outputs.version }} .
          docker push ${{ secrets.ECR_REGISTRY }}/app:${{ steps.version.outputs.version }}
      
      - name: Create release note
        run: |
          echo "Image: app:${{ steps.version.outputs.version }}" > release.txt
          echo "AMI: $(aws ec2 describe-images --filters Name=tag:Version,Values=${{ steps.version.outputs.version }} --query Images[0].ImageId --output text)" >> release.txt
```

**Step 3: Terraform Blue-Green Deployment**

```hcl
# variables.tf
variable "active_version" {
  type        = string
  description = "Active app version (blue or green)"
  default     = "blue"
  
  validation {
    condition     = contains(["blue", "green"], var.active_version)
    error_message = "Must be 'blue' or 'green'"
  }
}

variable "app_version_blue" {
  type        = string
  description = "Blue deployment app version"
  default     = "2.0.0"
}

variable "app_version_green" {
  type        = string
  description = "Green deployment app version"
  default     = "3.0.0"
}

# main.tf - Get pre-built AMIs
data "aws_ami" "app_blue" {
  most_recent = true
  owners      = ["self"]
  
  filter {
    name   = "name"
    values = ["app-${var.app_version_blue}"]
  }
  
  filter {
    name   = "tag:Version"
    values = [var.app_version_blue]
  }
}

data "aws_ami" "app_green" {
  most_recent = true
  owners      = ["self"]
  
  filter {
    name   = "name"
    values = ["app-${var.app_version_green}"]
  }
  
  filter {
    name   = "tag:Version"
    values = [var.app_version_green]
  }
}

# Launch templates for immutable instances
resource "aws_launch_template" "blue" {
  name_prefix   = "app-blue-"
  image_id      = data.aws_ami.app_blue.id
  instance_type = "t3.large"
  
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.common_tags,
      { Deployment = "blue", Version = var.app_version_blue }
    )
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "green" {
  name_prefix   = "app-green-"
  image_id      = data.aws_ami.app_green.id
  instance_type = "t3.large"
  
  tag_specifications {
    resource_type = "instance"
    tags = merge(
      local.common_tags,
      { Deployment = "green", Version = var.app_version_green }
    )
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# ASGs for both versions
resource "aws_autoscaling_group" "blue" {
  name                = "app-blue-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [aws_lb_target_group.blue.arn]
  
  min_size         = 2
  max_size         = 10
  desired_capacity = 3
  
  launch_template {
    id      = aws_launch_template.blue.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "app-blue"
    propagate_at_launch = true
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_autoscaling_group" "green" {
  name                = "app-green-asg"
  vpc_zone_identifier = var.subnet_ids
  target_group_arns   = [aws_lb_target_group.green.arn]
  
  min_size         = 0  # Start at 0, scale up during deployment
  max_size         = 10
  desired_capacity = var.active_version == "blue" ? 0 : 3
  
  launch_template {
    id      = aws_launch_template.green.id
    version = "$Latest"
  }
  
  tag {
    key                 = "Name"
    value               = "app-green"
    propagate_at_launch = true
  }
  
  lifecycle {
    create_before_destroy = true
  }
}

# Load Balancer Routes Traffic Based on Active Version
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"
  
  default_action {
    type = "forward"
    
    forward {
      target_group {
        arn    = var.active_version == "blue" ? aws_lb_target_group.blue.arn : aws_lb_target_group.green.arn
        weight = 100
      }
      
      # Setup for canary deployment (gradual rollout)
      target_group {
        arn    = var.active_version == "green" ? aws_lb_target_group.blue.arn : aws_lb_target_group.green.arn
        weight = 0  # Start at 0, increase during deployment
      }
    }
  }
}

# outputs.tf
output "blue_asg_name" {
  value = aws_autoscaling_group.blue.name
}

output "green_asg_name" {
  value = aws_autoscaling_group.green.name
}

output "active_deployment" {
  value = var.active_version
}
```

**Step 4: Deployment Playbook (Workflow)**

```bash
#!/bin/bash
# deploy.sh - Zero-downtime blue-green deployment

set -e

APP_VERSION="$1"
DEPLOYMENT_ENV="prod"

if [ -z "$APP_VERSION" ]; then
  echo "Usage: $0 <version>"
  exit 1
fi

echo "=== Zero-Downtime Blue-Green Deployment ==="
echo "Target version: $APP_VERSION"

# Step 1: Determine current active and inactive slots
echo "Step 1: Determine current deployment state..."
cd infrastructure/$DEPLOYMENT_ENV

ACTIVE=$(terraform output -raw active_deployment)
if [ "$ACTIVE" == "blue" ]; then
  INACTIVE="green"
  ACTIVE_VERSION=$(terraform output -raw app_version_blue)
else
  INACTIVE="blue"
  ACTIVE_VERSION=$(terraform output -raw app_version_green)
fi

echo "  Active: $ACTIVE ($ACTIVE_VERSION)"
echo "  Inactive: $INACTIVE"
echo "  Deploying: $APP_VERSION"

# Step 2: Update terraform.tfvars for inactive slot
echo ""
echo "Step 2: Update $INACTIVE deployment..."
if [ "$INACTIVE" == "green" ]; then
  sed -i "s/app_version_green = .*/app_version_green = \"$APP_VERSION\"/" terraform.tfvars
else
  sed -i "s/app_version_blue = .*/app_version_blue = \"$APP_VERSION\"/" terraform.tfvars
fi

echo "  Running terraform plan..."
terraform plan -out=deploy.tfplan

# Step 3: Apply infrastructure changes (scale up inactive)
echo ""
echo "Step 3: Provision new $INACTIVE instances..."
terraform apply deploy.tfplan

# Step 4: Wait for new instances to be healthy
echo ""
echo "Step 4: Waiting for $INACTIVE instances to become healthy..."

INACTIVE_ASG="$(terraform output -raw ${INACTIVE}_asg_name)"

while true; do
  HEALTHY=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$INACTIVE_ASG" \
    --query 'AutoScalingGroups[0].Instances[] | length(filter(@, &HealthStatus==`Healthy`))' \
    --output text)
  
  DESIRED=$(aws autoscaling describe-auto-scaling-groups \
    --auto-scaling-group-names "$INACTIVE_ASG" \
    --query 'AutoScalingGroups[0].DesiredCapacity' \
    --output text)
  
  echo "  $HEALTHY / $DESIRED instances healthy"
  
  if [ "$HEALTHY" -eq "$DESIRED" ]; then
    break
  fi
  
  sleep 10
done

# Step 5: Run smoke tests on new version
echo ""
echo "Step 5: Running smoke tests on $INACTIVE..."

INACTIVE_LB=$(terraform output -raw ${INACTIVE}_lb_dns)

for i in {1..5}; do
  curl -s "http://$INACTIVE_LB/health" | grep -q '"status":"ok"' && echo "  ✓ Health check passed" || (echo "  ✗ Health check failed" && exit 1)
  
  curl -s "http://$INACTIVE_LB/api/version" | grep -q "$APP_VERSION" && echo "  ✓ Version verified: $APP_VERSION" || (echo "  ✗ Version mismatch" && exit 1)
done

echo "  ✓ All smoke tests passed"

# Step 6: Canary deployment (Route 5% traffic to new version)
echo ""
echo "Step 6: Canary deployment (5% traffic to $INACTIVE)..."
echo "  Routes: $ACTIVE=95% | $INACTIVE=5%"

TERRAPORT_VARS=$(cat <<EOF
active_version = "$ACTIVE"
canary_weight = 5
EOF
)

echo "$TERRAFORM_VARS" >> terraform.tfvars
terraform apply -auto-approve

echo ""
echo "  Monitoring for 5 minutes (watch for errors)..."
sleep 300

# Check error rates
ERROR_RATE=$(aws cloudwatch get-metric-statistics \
  --namespace AWS/ApplicationELB \
  --metric-name HTTPCode_Target_5XX_Count \
  --start-time $(date -u -d '5 minutes ago' +%Y-%m-%dT%H:%M:%S) \
  --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
  --period 300 \
  --statistics Sum \
  --query 'Datapoints[0].Sum' --output text)

if [ "$ERROR_RATE" != "None" ] && [ "$(echo "$ERROR_RATE > 5" | bc)" -eq 1 ]; then
  echo "  ✗ High error rate detected! Aborting"
  exit 1
fi

echo "  ✓ Canary passed (no errors detected)"

# Step 7: Shift all traffic to new version
echo ""
echo "Step 7: Complete traffic shift to $INACTIVE..."
echo "  Routes: $ACTIVE=0% | $INACTIVE=100%"

sed -i 's/canary_weight = .*/canary_weight = 100/' terraform.tfvars
terraform apply -auto-approve

# Step 8: Monitor new active deployment
echo ""
echo "Step 8: Monitoring new active deployment for 10 minutes..."

for i in {1..10}; do
  ERROR_CHECK=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/ApplicationELB \
    --metric-name HTTPCode_Target_5XX_Count \
    --start-time $(date -u -d '1 minute ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 60 \
    --statistics Sum \
    --query 'Datapoints[0].Sum' --output text)
  
  if [ "$ERROR_CHECK" != "None" ] && [ "$(echo "$ERROR_CHECK > 2" | bc)" -eq 1 ]; then
    echo "  ✗ Errors detected! Rolling back..."
    # Instant rollback: revert active_version variable
    terraform apply -var="active_version=$ACTIVE" -auto-approve
    echo "  ✓ Rollback complete. Still running $ACTIVE"
    exit 1
  fi
  
  echo "  ✓ Minute $i: Healthy"
  sleep 60
done

echo ""
echo "=== Deployment Complete ==="
echo "✓ Successfully deployed $APP_VERSION to $DEPLOYMENT_ENV"
echo "✓ New active deployment: $INACTIVE"
echo "✓ Previous deployment ($ACTIVE) ready for rollback if needed"

# Step 9: Optional - Scale down old version after N hours
echo ""
echo "Note: Old $ACTIVE deployment still running (2 instances)"
echo "  Can be manually scaled down after validation period"
echo "  Or automatically via scheduled action"
```

**Step 5: Instant Rollback (If Needed)**

```bash
#!/bin/bash
# rollback.sh - Instant rollback to previous version

echo "=== Instant Rollback ==="

cd infrastructure/prod

# Get current active
ACTIVE=$(terraform output -raw active_deployment)

echo "Rolling back from: $ACTIVE"
echo "Rolling back to: ${ACTIVE%?}  # Swap blue <-> green"

if [ "$ACTIVE" == "blue" ]; then
  NEW_ACTIVE="green"
else
  NEW_ACTIVE="blue"
fi

# Single variable change reverts ALL traffic immediately
terraform apply -var="active_version=$NEW_ACTIVE" -auto-approve

echo "✓ Rollback complete (instant traffic shift)"
echo "Active deployment: $NEW_ACTIVE"

# Verify
sleep 30
curl -s http://$(terraform output -raw lb_dns)/health
```

#### Best Practices Demonstrated

1. **Immutable Images**
   - Configuration baked into AMI (no runtime setup)
   - Tested before production (smoke tests in Packer)
   - Instant startup (no waiting for `user_data`)

2. **Blue-Green Architecture**
   - Two complete environments running
   - Instant traffic switch via load balancer
   - Seamless rollback if issues detected

3. **Canary Deployments**
   - Gradually shift traffic (5% → 100%)
   - Detect issues early with small blast radius
   - Automatic rollback on error detection

4. **Zero-Downtime**
   - New instances healthy before traffic shift
   - Load balancer does instant switch
   - No application restarts

5. **Declarative Infrastructure**
   - Single variable change (`active_version`) controls traffic
   - No manual loadbalancer config changes
   - Easy rollback (just revert variable)

---

### Scenario 3: Refactoring Monolithic Terraform to Modular Design

#### Problem Statement

Your organization has a 2,500-line `main.tf` file managing:
- 50+ AWS resources
- 3 environments (dev, staging, prod)
- Multiple teams' infrastructure

**Problems:**
- Code is unmaintainable (hard to understand dependencies)
- Testing is difficult (can't isolate components)
- Reusability is zero (Team A writes VPC validation logic, Team B duplicates it)
- Changes risky (modifying anything could break everything)
- Onboarding new engineers difficult (no clear architecture)

**Goal**: Refactor to modular architecture while maintaining production availability.

#### Step 1: Analyze and Module Extraction

```hcl
// Current structure (MONOLITHIC):
// main.tf (2500 lines)
// ├─ VPC + Networking (200 lines)
// ├─ Security Groups (300 lines)
// ├─ EC2 Instances (400 lines)
// ├─ RDS Cluster (250 lines)
// ├─ Load Balancer (200 lines)
// ├─ Auto Scaling (150 lines)
// ├─ Monitoring (200 lines)
// ├─ IAM Roles (250 lines)
// └─ ...

// Target structure (MODULAR):
// terraform/
// ├── modules/
// │   ├── vpc/
// │   │   ├── main.tf
// │   │   ├── variables.tf
// │   │   └── outputs.tf
// │   ├── security/
// │   │   └── ...
// │   ├── compute/
// │   │   └── ...
// │   ├── database/
// │   │   └── ...
// │   └── monitoring/
// │       └── ...
// ├── environments/
// │   ├── dev/
// │   │   ├── main.tf         (Root module, uses ./modules)
// │   │   ├── terraform.tfvars
// │   │   └── backend.tf
// │   ├── staging/
// │   │   └── ...
// │   └── prod/
// │       └── ...
// └── README.md
```

**Step 2: Create Core Module: VPC**

```hcl
// modules/vpc/main.tf
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.common_tags,
    { Name = "${var.environment}-vpc" }
  )
}

resource "aws_subnet" "public" {
  count                   = length(var.availability_zones)
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.common_tags,
    { Name = "${var.environment}-public-subnet-${count.index + 1}" }
  )
}

resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + length(var.availability_zones))
  availability_zone = var.availability_zones[count.index]

  tags = merge(
    var.common_tags,
    { Name = "${var.environment}-private-subnet-${count.index + 1}" }
  )
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.common_tags,
    { Name = "${var.environment}-igw" }
  )
}

resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
  depends_on    = [aws_internet_gateway.main]

  tags = merge(
    var.common_tags,
    { Name = "${var.environment}-nat-${count.index + 1}" }
  )
}

resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = merge(
    var.common_tags,
    { Name = "${var.environment}-eip-nat-${count.index + 1}" }
  )
}

// Route tables and routes...

// modules/vpc/variables.tf
variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
  
  validation {
    condition     = can(cidrhost(var.vpc_cidr, 0))
    error_message = "VPC CIDR must be valid IPv4 CIDR block"
  }
}

variable "environment" {
  type        = string
  description = "Environment name (dev, staging, prod)"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "availability_zones" {
  type        = list(string)
  description = "List of AZs"
  
  validation {
    condition     = length(var.availability_zones) >= 2
    error_message = "Must specify at least 2 availability zones"
  }
}

variable "common_tags" {
  type        = map(string)
  description = "Common tags to apply to all resources"
}

// modules/vpc/outputs.tf
output "vpc_id" {
  value       = aws_vpc.main.id
  description = "VPC ID"
}

output "public_subnet_ids" {
  value       = aws_subnet.public[*].id
  description = "Public subnet IDs"
}

output "private_subnet_ids" {
  value       = aws_subnet.private[*].id
  description = "Private subnet IDs"
}
```

**Step 3: Root Module Using Modules**

```hcl
// environments/prod/main.tf
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

// Call VPC module
module "vpc" {
  source = "../../modules/vpc"

  vpc_cidr               = var.vpc_cidr
  environment            = var.environment
  availability_zones     = var.availability_zones
  common_tags            = local.common_tags
}

// Call Security module
module "security" {
  source = "../../modules/security"

  vpc_id                 = module.vpc.vpc_id
  environment            = var.environment
  common_tags            = local.common_tags
}

// Call Compute module
module "compute" {
  source = "../../modules/compute"

  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnet_ids
  security_group_ids     = [module.security.app_sg_id]
  environment            = var.environment
  instance_count         = var.instance_count
  instance_type          = var.instance_type
  common_tags            = local.common_tags
}

// Call Database module
module "database" {
  source = "../../modules/database"

  vpc_id                 = module.vpc.vpc_id
  subnet_ids             = module.vpc.private_subnet_ids
  security_group_id      = module.security.rds_sg_id
  environment            = var.environment
  common_tags            = local.common_tags
}

// Call Monitoring module
module "monitoring" {
  source = "../../modules/monitoring"

  environment            = var.environment
  instance_ids           = module.compute.instance_ids
  alb_arn                = module.load_balancer.alb_arn
  common_tags            = local.common_tags
}

locals {
  common_tags = merge(
    var.common_tags,
    {
      Environment = var.environment
      ManagedBy   = "Terraform"
      Project     = var.project_name
    }
  )
}

// environments/prod/variables.tf
variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "environment" {
  type = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Must be dev, staging, or prod"
  }
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "availability_zones" {
  type    = list(string)
  default = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "instance_count" {
  type    = number
  default = 3
}

variable "instance_type" {
  type    = string
  default = "t3.medium"
}

variable "common_tags" {
  type = map(string)
  default = {
    Owner = "platform-team"
  }
}

// environments/prod/terraform.tfvars
aws_region         = "us-east-1"
environment        = "prod"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
instance_count     = 5
instance_type      = "t3.large"
common_tags = {
  Owner       = "platform-team"
  CostCenter  = "engineering"
  Project     = "main-app"
}
```

**Step 4: Migration Strategy (Zero Downtime)**

```bash
#!/bin/bash
# migrate-to-modules.sh - No-downtime refactoring

set -e

echo "=== Terraform Refactoring (Monolithic → Modular) ==="

# Step 1: Backup current state
echo "Step 1: Backing up current state..."
cp prod/terraform.tfstate prod/terraform.tfstate.backup
cd prod

# Step 2: Create modules (parallel with existing main.tf)
echo "Step 2: Module structure created"
# (Done in previous step)

# Step 3: Use terraform state mv to reorganize (NOT delete/recreate)
echo "Step 3: Reorganizing state (mv not destruction)..."

# Move VPC resources to module namespace
terraform state mv \
  'aws_vpc.main' \
  'module.vpc.aws_vpc.main'

terraform state mv \
  'aws_subnet.public' \
  'module.vpc.aws_subnet.public'

terraform state mv \
  'aws_security_group.app' \
  'module.security.aws_security_group.app'

# ... continue for all resources

echo "  ✓ State reorganized (resources intact)"

# Step 4: Validate state consistency
echo "Step 4: Validating state..."
terraform state list | head -20
terraform state show | head -50

# Step 5: Test plan (should show no changes)
echo "Step 5: Verifying plan (should be empty)..."
CHANGES=$(terraform plan -json | jq -r '.resource_changes | length')

if [ "$CHANGES" -gt 0 ]; then
  echo "  ✗ Plan shows changes! Investigate:"
  terraform plan
  exit 1
fi

echo "  ✓ No changes detected (structure only)"

# Step 6: Archive old main.tf
echo "Step 6: Archiving old main.tf..."
mv main.tf main.tf.old

# Step 7: Create new modular main.tf
echo "Step 7: Creating new modular main.tf..."
# (Structure created in previous step)

# Step 8: Final validation
echo "Step 8: Final validation..."
terraform validate
terraform fmt -recursive

# Step 9: Apply (should modify nothing, only reformats)
echo "Step 9: Applying refactored structure..."
terraform apply

echo ""
echo "=== Refactoring Complete ==="
echo "✓ Migrated from monolithic to modular structure"
echo "✓ Zero downtime (resources unchanged)"
echo "✓ Old main.tf backed up as main.tf.old"
echo ""
echo "Next steps:"
echo "  1. Run tests in other environments (dev, staging)"
echo "  2. Code review modules"
echo "  3. Document module usage"
echo "  4. Remove main.tf.old after validation"
```

#### Benefits of Modular Refactoring

1. **Code Reusability**: VPC module used across all environments
2. **Maintainability**: Each module is <200 lines, single responsibility
3. **Testing**: Module can be tested independently
4. **Team Ownership**: Team A owns compute module, Team B owns database
5. **Scalability**: New projects reuse same modules
6. **Easier Documentation**: Each module has clear inputs/outputs

---

## Interview Questions

### Question 1: State Management Across Teams

**Question**: "Your organization has 4 teams managing infrastructure in a single AWS account. Each team uses Terraform independently. You're seeing state corruption, concurrent modifications, and lack of visibility. How would you design a centralized state management strategy while maintaining team autonomy?"

**Expected Answer**:

A senior DevOps engineer should discuss:

1. **Remote State Backend**
   - Centralized S3 backend with versioning enabled
   - DynamoDB table for state locking (prevents concurrent modifications)
   - Server-side encryption (at rest and in transit via TLS)
   - Enable MFA delete protection
   - Point-in-time recovery via S3 version history

2. **Access Control**
   ```hcl
   # backend.tf shared configuration
   terraform {
     backend "s3" {
       bucket         = "company-terraform-state"
       key            = "${TEAM_NAME}/${ENVIRONMENT}/terraform.tfstate"
       region         = "us-east-1"
       encrypt        = true
       dynamodb_table = "terraform-locks"
     }
   }
   ```

   - IAM policy per team (least privilege)
   - Team A can only access `team-a/**` state
   - Prevent accidental cross-team modifications
   - Audit CloudTrail for state access

3. **Architecture for Autonomy + Central Control**
   ```
   Centralized Backend:
   ├─ S3: company-terraform-state (single bucket)
   │  ├─ team-a/
   │  │  ├─ dev/terraform.tfstate
   │  │  ├─ staging/terraform.tfstate
   │  │  └─ prod/terraform.tfstate
   │  ├─ team-b/
   │  │  └─ ...
   │  └─ ...
   └─ DynamoDB: terraform-locks (single table)
      └─ Entries automatically created per state file
   
   Team Autonomy:
   ├─ Each team manages own modules
   ├─ Each team controls own variables
   ├─ Each team follows standard structure
   └─ Enforcement via Terraform Cloud policies
   ```

4. **Handling State Corruption Recovery**
   - S3 versioning allows "rollback" to previous state
   - Never store secrets in state (use Secrets Manager)
   - Use `terraform state rm` to remove orphaned resources
   - `terraform import` to readopt resources

5. **Organization & Governance**
   - Terraform Cloud/Enterprise enforces policies
   - Cost management per team
   - Approval workflows before apply
   - Audit logging of all changes

**Follow-up Consideration**: How would you handle a team accidentally modifying another team's state?
- Should use stronger IAM policies + separate AWS accounts per team
- Or implement attribute-based access control (ABAC)

---

### Question 2: Disaster Recovery - Recreating Infrastructure

**Question**: "Your production Terraform state file is corrupted (git merge conflict introduced invalid JSON). You have live infrastructure running but can't run `terraform apply` without risking destruction. How do you recover without downtime?"

**Expected Answer**:

A senior engineer should immediately recognize this is a **state recovery scenario** requiring careful steps:

1. **Immediate Actions (Don't Panic)**
   ```bash
   # DO NOT run terraform plan or apply yet!
   # Step 1: Verify state file corruption
   terraform validate
   # Output: Error: Could not parse backend config...
   
   # Step 2: Examine state file
   cat terraform.tfstate | jq .
   # Confirm if corrupted (invalid JSON)
   ```

2. **Recovery Options**

   **Option A: Use S3 Versioning (Best)**
   ```bash
   # If using S3 with versioning (recommended)
   aws s3api list-object-versions \
     --bucket company-terraform-state \
     --prefix prod/terraform.tfstate
   
   # Restore previous version
   aws s3api get-object \
     --bucket company-terraform-state \
     --key prod/terraform.tfstate \
     --version-id 'abc123xyz' \
     terraform.tfstate.recovered
   
   # Validate recovered state
   cp terraform.tfstate terraform.tfstate.corrupted
   cp terraform.tfstate.recovered terraform.tfstate
   terraform validate
   # Should work now
   ```

   **Option B: Commit History (Git)**
   ```bash
   # If state file in git (NOT recommended but sometimes done)
   git log --oneline terraform.tfstate | head -10
   git checkout <commit-hash>^ -- terraform.tfstate
   terraform validate
   ```

   **Option C: Rebuild State (Last Resort)**
   ```bash
   # If no backups (shouldn't happen with proper backend config)
   # Must re-import all resources
   
   # Create new state file from scratch
   rm terraform.tfstate*
   terraform init  # Re-initializes state
   
   # Import all existing resources
   aws ec2 describe-instances --query 'Reservations[*].Instances[*].InstanceId' --output text | tr '\t' '\n' | while read instance; do
     terraform import aws_instance.web $instance
   done
   
   # Takes hours for large infrastructure
   # High risk of mistakes
   ```

3. **Prevention (Going Forward)**
   ```hcl
   # terraform backend config must enforce:
   {
     "bucket": "company-terraform-state",
     "versioning": true,      # Critical!
     "server_side_encryption_configuration": {},
     "lifecycle_rules": [{     # Keep versions
       "noncurrent_version_expiration": 90
     }],
     "mfa_delete": true,      # Protect against deletion
   }
   ```

4. **Testing Recovery Plan**
   - Monthly dry-runs of state recovery
   - Document recovery procedures
   - Ensure team knows steps

**Follow-up**: How would you prevent this in the first place?
- Backend state should never be in Git (use remote backend)
- CI/CD should validate state file syntax
- Use `.gitignore` to prevent state commits

---

### Question 3: Managing Secrets in Terraform

**Question**: "Your team uses Terraform to provision databases with passwords stored in terraform.tfvars. Code review shows this is a security risk. How would you refactor to properly manage secrets while keeping developers productive and variables reusable across environments?"

**Expected Answer**:

A senior engineer should demonstrate deep understanding of secret management:

1. **Problem with Current Approach**
   ```hcl
   # INSECURE
   variable "rds_password" {}
   # In terraform.tfvars:
   # rds_password = "P@ssw0rd123!"  # In plain text in Git!
   
   # Risks:
   # - Git history forever contains password
   # - Anyone with repo access sees password
   # - Rotating password means new Git commit
   # - Difficult to expire/revoke
   ```

2. **Solution 1: AWS Secrets Manager + Terraform**
   ```hcl
   # Store password in Secrets Manager (outside Terraform)
   resource "aws_secretsmanager_secret" "rds_password" {
     name = "prod/rds/master-password"
   }
   
   resource "aws_secretsmanager_secret_version" "rds_password" {
     secret_id     = aws_secretsmanager_secret.rds_password.id
     secret_string = random_password.rds.result
   }
   
   # Reference in RDS (no password in state!)
   resource "aws_rds_cluster" "main" {
     master_username = "admin"
     master_password = jsondecode(
       aws_secretsmanager_secret_version.rds_password.secret_string
     )["password"]
   }
   ```

3. **Solution 2: Environment Variables**
   ```bash
   # CI/CD passes secrets as env vars, NOT in tfvars
   export TF_VAR_rds_password=$(aws secretsmanager get-secret-value --secret-id prod/rds --query SecretString --output text)
   terraform apply
   ```

4. **Solution 3: Terraform Cloud (Enterprise)**
   ```
   Terraform Cloud Variables Interface:
   ├─ Environment Variable: Marked as Sensitive
   ├─ Encrypted at rest
   ├─ Never logged
   ├─ Easy rotation
   └─ No Git commits needed
   ```

5. **Solution 4: HashiCorp Vault**
   ```hcl
   # For advanced secret management
   provider "vault" {
     address = "https://vault.company.com"
   }
   
   data "vault_generic_secret" "rds_password" {
     path = "secret/prod/rds"
   }
   
   resource "aws_rds_cluster" "main" {
     master_password = data.vault_generic_secret.rds_password.data["password"]
   }
   
   # Benefits:
   # - Centralized secret management
   # - Short-lived credentials
   # - Audit logging
   # - Fine-grained access control
   # - Automatic rotation
   ```

6. **Best Practice Architecture**
   ```
   Git Repository (No Secrets)
   ├─ main.tf
   ├─ variables.tf
   └─ .gitignore
      └─ terraform.tfvars (never committed)
   
   Secure Secret Storage (Separate from Code)
   ├─ AWS Secrets Manager (simple)
   ├─ HashiCorp Vault (advanced)
   └─ Terraform Cloud Sensitive Variables
   
   CI/CD Pipeline
   ├─ Checkout code
   ├─ Retrieve secrets from manager
   ├─ Run terraform apply
   └─ Secrets never logged
   ```

7. **Handling Secret Rotation**
   ```bash
   # Terraform should NOT manage password creation
   # Passwords created externally, referenced by Terraform
   
   # Rotation process:
   # 1. DBA updates Secrets Manager
   # 2. Terraform reads new value
   # 3. terraform apply updates resource
   # 4. Old password stops working automatically
   ```

**Follow-up**: How would you enforce this policy across teams?
- Pre-commit hooks check for hardcoded secrets
- Terraform validation that no passwords in tfvars
- Secrets manager integration required before apply

---

### Question 4: High Availability & Disaster Recovery

**Question**: "Design a high-availability Terraform setup for an e-commerce platform. Describe how you'd handle multi-region deployment, failover, and ensure infrastructure can be rapidly recreated if entire region fails."

**Expected Answer**:

This is an architecture question requiring systems thinking:

1. **Multi-Region State Strategy**
   ```
   Primary Region (us-east-1):
   ├─ Main Terraform state (S3 with replication)
   ├─ Production infrastructure
   └─ CloudFront origin server
   
   Secondary Region (us-west-2):
   ├─ Replicated S3 state file (read-only)
   ├─ Standby infrastructure (auto-scaling to 0)
   └─ Route53 failover records configured
   ```

2. **Terraform Code Organization for Multi-Region**
   ```hcl
   // Global resources
   terraform/
   ├─ global/
   │  ├─ main.tf (Route53, CloudFront)
   │  └─ backend.tf (global state)
   └─ regions/
      ├─ us-east-1/ (primary)
      │  ├─ main.tf
      │  ├─ terraform.tfstate
      │  └─ backend.tf (region-specific backend)
      └─ us-west-2/ (secondary)
         ├─ main.tf    (identical to primary!)
         ├─ terraform.tfstate
         └─ backend.tf (replicated to this region)
   
   Key insight: Infrastructure code identical, only state separated
   ```

3. **High Availability Architecture**
   ```
   Internet Users
   ↓
   Route53 (DNS failover)
   ├─ Primary Health Check (us-east-1)
   └─ Secondary Health Check (us-west-2)
   ↓
   CloudFront (Global Edge Cache)
   ├─ Origin 1: us-east-1 ALB
   └─ Origin 2: us-west-2 ALB (failover)
   ↓
   Application ALB
   ↓
   Auto Scaling Group (multi-AZ within region)
   ↓
   EC2 Instances + RDS Aurora (multi-master)
   ```

4. **Cross-Region Replication**
   ```hcl
   # Primary region
   resource "aws_rds_cluster" "primary" {
     cluster_identifier = "primary-cluster"
     availability_zones = ["us-east-1a", "us-east-1b", "us-east-1c"]
     
     enable_http_endpoint = true  # Allows failover detection
   }
   
   # Secondary region - Global Database
   resource "aws_rds_cluster" "secondary" {
     provider                  = aws.secondary
     global_cluster_identifier = aws_rds_global_cluster.main.id
     cluster_identifier        = "secondary-cluster"
   }
   
   # Bi-directional replication
   resource "aws_rds_global_cluster" "main" {
     global_cluster_identifier = "global-db"
     engine                    = "aurora-mysql"
     engine_version            = "8.0.mysql_aurora.3.02.0"
   }
   ```

5. **Failover Automation**
   ```bash
   #!/bin/bash
   # Failover procedure on primary region failure
   
   # Step 1: Detect failure
   HEALTH=$(aws route53 get-health-check-status \
     --health-check-id us-east-1-check \
     --region us-west-2 \
     --query 'HealthCheckObservations[0].StatusReport.Status' --output text)
   
   if [ "$HEALTH" != "Success" ]; then
     echo "Primary region failed. Initiating failover..."
     
     # Step 2: Promote secondary database
     aws rds modify-db-cluster \
       --db-cluster-identifier secondary-cluster \
       --enable-global-write-forwarding false  # Becomes writable
     
     # Step 3: Update Route53
     aws route53 change-resource-record-sets \
       --hosted-zone-id Z123ABC \
       --change-batch '{
         "Changes": [{
           "Action": "UPSERT",
           "ResourceRecordSet": {
             "Name": "api.example.com",
             "Type": "A",
             "AliasTarget": {
               "HostedZoneId": "us-west-2-zone-id",
               "DNSName": "us-west-2-alb.amazonaws.com",
               "EvaluateTargetHealth": true
             }
           }
         }]
       }'
     
     # Step 4: Scale up standby infrastructure
     aws autoscaling set-desired-capacity \
       --auto-scaling-group-name us-west-2-asg \
       --desired-capacity 10
     
     echo "Failover complete. Now serving from us-west-2"
   fi
   ```

6. **Rapid Recovery (If Primary Recovers)**
   ```bash
   #!/bin/bash
   # Recovery process to restore original primary-secondary relationship
   
   # Step 1: Verify primary is truly healthy
   # (health checks for 5 minutes straight)
   
   # Step 2: Demote secondary back to standby
   aws rds modify-db-cluster \
     --db-cluster-identifier secondary-cluster \
     --enable-iap-auth  # Standby mode
   
   # Step 3: Repoint Route53
   # (Routes traffic back to us-east-1)
   
   # Step 4: Sync application state from secondary to primary
   # (Could include S3, ElastiCache, etc.)
   
   # Step 5: Gradual traffic shift (5% → 100%)
   # (Monitor error rates, automatic rollback if needed)
   ```

7. **Testing HA Setup**
   ```bash
   # Monthly DR drills
   # 1. Promote secondary to primary (read-write)
   # 2. Run full application test suite
   # 3. Measure failover time RTO (usually <5 min)
   # 4. Measure data loss RPO (usually <1 min)
   # 5. Restore original state
   ```

**Key Metrics**:
- **RTO** (Recovery Time Objective): <5 minutes
- **RPO** (Recovery Point Objective): <1 minute
- **Availability**: 99.99% (52 minutes/year downtime max)

---

### Question 5: State Locking and Concurrency Control

**Question**: "Two engineers run `terraform apply` simultaneously on the same production Terraform workspace. What happens? How would you prevent this?"

**Expected Answer**:

A senior engineer should understand state locking mechanics:

1. **What Happens Without Locking**
   ```
   Engineer A                      Engineer B
   │                              │
   ├─ Read current state          │
   │ (Sees 3 EC2 instances)       │
   │                              ├─ Read current state
   ├─ Run terraform plan          │ (Sees same 3 EC2 instances)
   │ Shows: Create 2 instances    │
   │                              ├─ Run terraform plan  
   ├─ Apply changes               │ Shows: Delete 1 instance
   │ (Creates 2 new instances)    │
   │ State now: 5 instances       │
   │ (WRONG! Was supposed to be 4)│
   │                              ├─ Apply changes
   │                              │ (Deletes 1 instance)
   │                              │ State now: 4instances
   │                              │ (LOST Engineer A's changes!)
   │                              │
   Result: State corruption, infrastructure out of sync
   ```

2. **State Locking Prevention**
   ```hcl
   # DynamoDB-based locking (for S3 backend)
   terraform {
     backend "s3" {
       bucket         = "company-terraform-state"
       key            = "prod/terraform.tfstate"
       dynamodb_table = "terraform-locks"  # This is KEY
       region         = "us-east-1"
     }
   }
   
   # DynamoDB table structure:
   # - Primary Key: LockID (unique identifier for state file)
   # - Attributes: Who locked, When, Why (expiration time)
   
   # On terraform apply:
   # 1. Tries to create DynamoDB item with LockID
   # 2. If item exists, apply is blocked (engineer B waits)
   # 3. Engineer A's apply finishes, deletes lock
   # 4. Engineer B's apply proceeds
   ```

3. **Lock Implementation Details**
   ```bash
   # When Engineer A runs terraform apply:
   
   # Terraform creates lock:
   {
     "LockID": "company-terraform-state/prod/terraform.tfstate",
     "Info": {
       "ID": "unique-session-id",
       "Operation": "OperationTypeApply",
       "Info": "",
       "Who": "alice@company.com",
       "Version": "1.5.0",
       "Created": "2024-03-07T10:15:30Z",
       "Path": "/prod/terraform.tfstate"
     }
   }
   
   # Engineer B tries to apply, sees item exists, gets error:
   # Error: Error acquiring the state lock
   # Lock Info:
   #   ID:        abc-123-xyz
   #   Path:      prod/terraform.tfstate
   #   Operation: OperationTypeApply
   #   Who:       alice@company.com
   #   Version:   1.5.0
   #   Created:   2024-03-07 10:15:30
   #   Info:
   #
   # Terraform will continue retrying for 10 minutes (configurable).
   # Engineer B must wait.
   ```

4. **Lock Management**
   ```bash
   # View current locks
   terraform force-unlock <LOCK_ID>
   # (Only to be used if lock holder's process crashed)
   
   # Monitor locks in production
   aws dynamodb scan \
     --table-name terraform-locks \
     --query 'Items[*].LockID.S' --output table
   ```

5. **Best Practices for Concurrency**
   ```hcl
   # Use separate workspaces for different engineers
   # (Don't work on same state simultaneously)
   
   # terraform workspace new alice
   # terraform workspace new bob
   # Each has own state file
   
   # Or separate state files per environment
   # backend key: prod vs staging
   ```

6. **Investigation After Corruption**
   ```bash
   # If state corrupted despite locking:
   
   # Step 1: Check DynamoDB lock history
   aws dynamodb get-item --table-name terraform-locks \
     --key "{\"LockID\":{\"S\":\"...\"}}"
   
   # Step 2: Check S3 version history
   aws s3api list-object-versions \
     --bucket company-terraform-state
   
   # Step 3: Who accessed state? (CloudTrail)
   aws logs get-log-events \
     --log-group-name CloudTrail \
     --filter-pattern "terraform.tfs"
   
   # Step 4: Determine which version was "correct"
   # Could be time-based or content-based
   ```

**Critical Point**: Locking prevents but does NOT prevent misconfiguration. It prevents:
- Concurrent state modifications
- File corruption from simultaneous writes

It does NOT prevent:
- Incorrect Terraform code destroying resources
- Engineers accidentally pointing to wrong state file
- State file encryption compromise

---

### Question 6: Backward Compatibility and Breaking Changes

**Question**: "You've maintained a Terraform module for 2 years. Now you want to refactor it with breaking changes (rename variables, restructure outputs). How do you release this without breaking 8 teams currently depending on it?"

**Expected Answer**:

This tests understanding of module versioning and change management:

1. **The Challenge**
   ```
   Current Module v1.0.0 (8 teams using it):
   
   module "vpc" {
     source = "git::https://github.com/company/tf-modules.git//vpc?ref=v1.0.0"
     
     vpc_cidr = "10.0.0.0/16"
     public_subnets = ["10.0.0.0/24", "10.0.1.0/24"]
     enable_nat = true
   }
   
   Desired Changes for v2.0.0:
   - Rename vpc_cidr → vpc_ipv4_cidr (more semantically correct)
   - Rename public_subnets → public_subnet_cidrs
   - Output: public_subnet_ids → public_subnets
   - Remove enable_nat (always enabled now)
   
   Problem: If teams just "upgrade" to v2.0.0, code BREAKS
   Team A's code using old variable names won't work
   ```

2. **Solution: Semantic Versioning & Deprecation**
   ```
   v1.0.0 (Current, EOL in 6 months)
   ├─ Supports old variable names
   ├─ Shows deprecation warnings
   └─ Documentation: "Upgrade to v2.0.0"
   
   v1.5.0 (Compatibility Shim, 6 months)
   ├─ Supports BOTH old and new variable names
   ├─ New names take priority
   ├─ Strong deprecation warnings for old names
   └─ Changelog: "Plan migration to v2.0.0"
   
   v2.0.0 (Clean API, long-term support)
   ├─ Only new variable names
   ├─ Cleaner code
   └─ All old names removed
   ```

3. **Implementation of v1.5.0 (Compatibility Layer)**
   ```hcl
   // vpc/variables.tf
   variable "vpc_ipv4_cidr" {
     type        = string
     description = "VPC CIDR block (IPv4)"
   }
   
   # Deprecated variable for backward compatibility
   variable "vpc_cidr" {
     type        = string
     default     = null
     description = "DEPRECATED: Use vpc_ipv4_cidr instead"
   }
   
   # Migrate old name to new name
   locals {
     actual_vpc_cidr = var.vpc_cidr != null ? var.vpc_cidr : var.vpc_ipv4_cidr
     
     # Warning for deprecated variable
     deprecated_warning = var.vpc_cidr != null ? (
       file("ERROR: Variable 'vpc_cidr' is deprecated. Use 'vpc_ipv4_cidr' instead.")
     ) : ""
   }
   
   resource "aws_vpc" "main" {
     cidr_block = local.actual_vpc_cidr  # Uses compatible value
   }
   ```

4. **Release Process and Communication**

   **Month 1: Announce Breaking Changes**
   ```
   BREAKING
   CHANGES
   v2.0.0
   
   Subject: VPC Module v2.0.0 - Breaking Changes Coming
   
   Timeline:
    - v1.5.0 (March 15): Compatibility layer + deprecation warnings
    - v2.0.0 (June 15): Breaking changes effective
   
   Migration Guide:
    - Rename vpc_cidr → vpc_ipv4_cidr in your code
    - Rename public_subnets → public_subnet_cidrs
    - Update output references
   
   Migration Tool:
    - Provided: sed script to auto-update code
    - Test in lower environments first
   
   Support:
    - Open deprecation PR? We'll help migrate
    - Questions? Slack #infrastructure-team
   ```

   **Month 2-5: v1.5.0 in Production**
   ```
   # Migration can happen incrementally
   Team A: Upgrades immediately
   Team B: Upgrades in sprint 3
   Team C: Upgrades after feature freeze
   Team D: Upgrades when convenient (but before v2.0.0)
   
   All can use v1.5.0 during this period (both APIs work)
   ```

   **Month 6: v2.0.0 Released**
   ```
   # All teams have migrated
   # v2.0.0 becomes new standard
   # v1.0.0 tagged as deprecated
   ```

5. **Automated Migration Tool**
   ```bash
   #!/bin/bash
   # migrate-vpc-module.sh - Auto migrate to v2.0.0 API
   
   DIRECTORY="${1:-.}"
   
   # Find all terraform files referencing vpc module
   find "$DIRECTORY" -name '*.tf' -type f | while read file; do
     sed -i '' \
       -e 's/vpc_cidr =/vpc_ipv4_cidr =/g' \
       -e 's/public_subnets =/public_subnet_cidrs =/g' \
       -e 's/module\.vpc\.public_subnet_ids/module.vpc.public_subnets/g' \
       "$file"
   done
   
   echo "Migration complete. Please test in lower environments first."
   ```

6. **Testing Strategy**
   ```hcl
   # Test v1.5.0 compatibility thoroughly
   
   # Test old API still works
   module "vpc_old_api" {
     source = "./"
     vpc_cidr = "10.0.0.0/16"  # OLD name
     public_subnets = [...]
   }
   
   # Test new API works
   module "vpc_new_api" {
     source = "./"
     vpc_ipv4_cidr = "10.0.0.0/16"  # NEW name  
     public_subnet_cidrs = [...]
   }
   
   # Both should produce identical output
   output "old_api_id" {
     value = module.vpc_old_api.vpc_id
   }
   
   output "new_api_id" {
     value = module.vpc_new_api.vpc_id
   }
   # These should be equal in tests
   ```

**Key Principles**:
- **Semantic Versioning**: MAJOR.MINOR.PATCH (2.0.0 = breaking changes)
- **Deprecation Period**: At least 6 months notice
- **Compatibility Layers**: Support both old and new for transition period
- **Clear Communication**: Announce early, document thoroughly
- **Tooling Support**: Provide scripts/tools to migrate

---

### Question 7-12: Additional Senior-Level Interview Questions

**Question 7: Scaling Challenges**
"Your `terraform apply` now takes 45 minutes on a stack with 2,000 resources. From 15 minutes previously. What could cause this slowdown and how do you diagnose and fix it?"

*Expected Topics*:
- API rate limiting from cloud providers
- Graph evaluation bottlenecks
- Slow data source queries
- Remote state latency
- Use `terraform graph` to analyze dependencies
- Parallelism with `-parallelism=N`
- Profiling with TF_LOG=DEBUG
- Breaking into smaller independent stacks
Example cause: New data source querying all 10,000 AWS instances for filtering

---

**Question 8: Cost Optimization**
"Using Terraform, how would you implement automatic cost optimization? Examples: Scheduling dev environment shutdown, right-sizing instances, removing unused resources."

*Expected Topics*:
- AWS Instance Scheduler + Terraform automation
- Tagging strategy for cost allocation
- Scheduled Lambda to analyze unused resources
- Terraform cost estimation (Infracost tool)
- Reserved instances vs on-demand decisions
- Spot instance integration
- CI/CD policy preventing expensive resources

---

**Question 9: Policy as Code**
"Implement a Terraform policy that prevents engineers from:
1. Creating publicly accessible S3 buckets
2. Creating RDS databases without backups enabled
3. Using old insecure TLS versions
How would you enforce this across teams?"

*Expected Topics*:
- Terraform Cloud sentinel policies (or OPA/Rego)
- Pre-commit hooks with tflint + custom rules
- CI/CD pipeline validation before approve
- Cost examples of policy violations
- Trade-offs: strictness vs developer friction

---

**Question 10: Module Testing**
"Design a comprehensive testing strategy for Terraform modules. How do you test that a module works correctly without standing up actual AWS infrastructure every test?"

*Expected Topics*:
- Unit tests: terraform validate, terraform fmt
- Integration tests: Terratest (Go-based framework)
- Cost/time of full infrastructure tests
- Mock testing vs real AWS testing
- CI/CD test stages
- Automated tests on PR before merge

---

**Question 11: GitOps Workflow**
"Describe a complete GitOps workflow for infrastructure. How do PRs, code reviews, approvals, and automatic deployments work together?"

*Expected Topics*:
- Git as source of truth
- terraform plan as PR comment
- Approval workflows before apply
- Automated drift detection
- Rollback procedures
- Audit logging of who approved what

---

**Question 12: Migrating Existing Infrastructure**
"Your company has 2 years of manually created AWS infrastructure (no Terraform). How do you gradually migrate to Terraform without downtime or resource recreation?"

*Expected Topics*:
- Using `terraform import` to adopt resources
- Gradual adoption (high-value resources first)
- Refactoring non-critical resources
- Testing imports in lower environments
- Handling state file conflicts
- Documentation of manual workarounds

---

**Document Version**: 2.0  
**Last Updated**: March 7, 2026  
**Audience**: Senior DevOps Engineers (5-10+ years)  
**Status**: Complete - All sections finalized
