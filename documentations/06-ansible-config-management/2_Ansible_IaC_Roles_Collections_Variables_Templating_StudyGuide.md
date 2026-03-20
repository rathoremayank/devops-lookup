# Ansible for Infrastructure as Code: Roles & Collections, Variables & Templating, Modules & Execution Strategies

**Study Guide for Senior DevOps Engineers**

---

## Table of Contents

1. [Introduction](#introduction)
2. [Foundational Concepts](#foundational-concepts)
3. [Roles & Collections](#roles--collections)
4. [Variables & Templating](#variables--templating)
5. [Ansible Modules & Custom Modules](#ansible-modules--custom-modules)
6. [Ansible Execution Strategies](#ansible-execution-strategies)
7. [Hands-on Scenarios](#hands-on-scenarios)
8. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Topic

Ansible has evolved from a simple configuration management tool into a comprehensive Infrastructure as Code (IaC) platform. This study guide focuses on the advanced architectural patterns and technical capabilities that enable enterprise-scale automation: **Roles & Collections** for code organization and reusability, **Variables & Templating** for dynamic configuration, **Ansible Modules** for extensible automation, and **Execution Strategies** for performance optimization and advanced orchestration.

These four pillars form the foundation of production-grade Ansible deployments, where infrastructure complexity demands modular architecture, robust variable management, extensible capabilities, and performance-tuned execution models.

### Why It Matters in Modern DevOps Platforms

In modern DevOps ecosystems, infrastructure automation must address several critical challenges:

- **Scalability & Reusability**: Organizations manage hundreds or thousands of infrastructure components across multiple environments. Monolithic playbooks become unmaintainable. Roles and Collections enable a modular, library-based approach where automation code becomes a strategic asset.

- **Configuration Complexity**: Modern infrastructure spans multiple cloud providers, requires dynamic host discovery, environment-specific configurations, and integration with CI/CD pipelines. Variables and Templating provide the abstraction layer to manage this complexity without duplicating logic.

- **Extensibility Requirements**: Standard Ansible modules may not cover specialized infrastructure needs (custom cloud APIs, proprietary tools, legacy systems). Custom module development enables teams to extend Ansible's capabilities without external dependencies or workarounds.

- **Performance & Orchestration Control**: As infrastructure scales, execution performance and control become critical. Execution strategies determine how plays run across inventory, impacting deployment speed, failure recovery, and resource utilization.

- **Enterprise Standardization**: Collections provide a standardized, versioned, and discoverable mechanism for sharing automation across teams, enabling consistent infrastructure practices at scale.

### Real-World Production Use Cases

#### Multi-Cloud Infrastructure Deployment
**Scenario**: A SaaS company manages infrastructure across AWS, Azure, and GCP with environment-specific configurations (dev, staging, production).

**Application**:
- **Collections**: Use provider-specific collections (`community.aws`, `azure.azcollection`, `google.cloud`) alongside internal collections for organizational standards
- **Roles**: Create abstraction roles for compute provisioning, networking, security that delegate to provider-specific tasks
- **Variables**: Environment variable files define region, instance types, security groups; templating generates cloud-specific manifests
- **Execution Strategy**: Use `serial: 2` to perform rolling deployments, preventing simultaneous updates to critical infrastructure
- **Result**: Single playbook orchestrates consistent infrastructure across clouds, with provider abstraction hiding implementation details

#### Kubernetes Cluster Lifecycle Management
**Scenario**: Operations team manages 10+ Kubernetes clusters at various lifecycle stages (provisioning, updates, security patches, decommissioning).

**Application**:
- **Collections**: Kubernetes collection for cluster management, custom collection for organization-specific policies
- **Roles**: K8s node preparation, etcd backup, network policy enforcement, cluster upgrade orchestration
- **Variables**: Cluster inventory with node counts, Kubernetes versions, network CIDRs; templates generate manifests for workload deployment
- **Custom Modules**: Module to query cluster state and trigger drain/cordon operations
- **Execution Strategy**: `host_pinned` strategy ensures consistent node operations; `async` for long-running tasks (e.g., node drains)
- **Result**: Declarative cluster lifecycle management with tight orchestration control

#### Disaster Recovery & Compliance Automation
**Scenario**: Regulated industry requires weekly DR tests, compliance configuration enforcement, and audit logging.

**Application**:
- **Collections**: Versioned collections ensure all DR tests use consistent automation
- **Roles**: Backup verification, failover testing, compliance state validation
- **Variables**: Backup retention policies, DR region configurations, compliance baselines as variables
- **Templating**: Generate audit reports, compliance state reports from templates
- **Custom Modules**: Module to validate infrastructure compliance against policy, returning structured compliance status
- **Execution Strategy**: `linear` strategy with detailed failure handling; `serial: 1` for sensitive operations requiring step-by-step monitoring
- **Result**: Fully automated, auditable DR processes and compliance enforcement

### Where It Typically Appears in Cloud Architecture

These Ansible capabilities typically operate at multiple layers in cloud architecture:

```
┌─────────────────────────────────────────────────────────────┐
│  Application Layer (Kubernetes, microservices)              │
│  - Collections: workload management, GitOps                 │
│  - Roles: deployment automation, upgrades                   │
│  - Modules: custom workload controllers                     │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Platform Layer (Kubernetes runtime, service mesh)          │
│  - Collections: Istio, ingress, CNI management              │
│  - Roles: platform setup, security policies                 │
│  - Execution Strategies: coordinated platform updates       │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Infrastructure Layer (Compute, networking, storage)        │
│  - Collections: cloud provider collections                  │
│  - Roles: infrastructure provisioning, security groups      │
│  - Variables: cloud resource specifications                 │
│  - Custom Modules: custom cloud API interactions            │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│  Control Plane (Ansible control node)                       │
│  - Playbooks orchestrate multi-layer deployments            │
│  - Roles and Collections provide reusable components        │
│  - Dynamic inventory integrates with cloud platforms        │
└─────────────────────────────────────────────────────────────┘
```

In GitOps workflows, Ansible Collections often serve as the automation engine for continuous deployment pipelines. In hybrid cloud environments, Roles provide the abstraction layer that enables uniform infrastructure management across on-premises and public cloud. In enterprise organizations, Collections become the standardized distribution mechanism for approved automation patterns.

---

## Foundational Concepts

### Key Terminology

**Idempotency**: A core Ansible principle where running a playbook multiple times produces the same final state. This is critical for infrastructure automation—operations should be safe to retry without corrupting state or creating duplicate resources.

**Declarative vs. Imperative**: Ansible playbooks are *declarative* (specify desired state) not *imperative* (list steps). This distinction shapes how Roles and Modules are designed—modules describe state changes, not command sequences.

**Inventory**: The collection of hosts Ansible manages. Inventory can be static (file-based) or dynamic (queried from cloud providers, configuration management databases). Understanding inventory structure is essential for Variables and Execution Strategies.

**Play**: A set of tasks executed against a specific set of hosts. A playbook contains one or more plays. Execution Strategies operate at the play level.

**Task**: The atomic unit of work—a call to a module with arguments. A role consists of multiple tasks organized by purpose (create resources, configure, validate).

**Handler**: A special task triggered by `notify` directives from other tasks. Handlers run once at the end of a play even if triggered multiple times—essential for operations like service restarts.

**Fact**: Host metadata discovered by Ansible (OS, IP addresses, available memory). Facts are gathered at play start and available as variables throughout the play.

**Variable Precedence**: The priority order determining which variable value is used when multiple sources define the same variable. This is crucial for managing variable complexity in large deployments.

**Collection**: A distribution format for Ansible content (roles, modules, plugins) with explicit versioning. Collections are installed from Galaxy, local repositories, or enterprise registries.

**Role**: A pre-packaged automation component with defined interface and idempotent behavior. Roles are the primary reuse mechanism in Ansible playbooks.

**Module**: Python code that executes on target hosts or locally. Modules are the actual automation primitives—everything else in Ansible is orchestration around modules.

### Architecture Fundamentals

#### Ansible Execution Model

```
Control Node (Ansible installed)
    ↓
[Inventory parsing] ← Defines target hosts and variables
    ↓
[Play execution] ← Determines execution strategy
    ↓
[Task execution against hosts] ← Modules run here
    ↓
[Result aggregation] ← Facts and results returned
```

**Key Point**: Ansible operates primarily over SSH (by default). For each task, Ansible transfers Python code to the target host, executes it, collects results, and continues to the next task. This stateless model enables scaling.

#### Variable Resolution System

Variables in Ansible come from multiple sources with a defined precedence order (low to high priority):

1. **Defaults** (lowest priority)
   - Role defaults: `roles/myrole/defaults/main.yml`
   - Used as initial values

2. **Variables** (inventory and playbook)
   - Inventory group variables: `group_vars/` 
   - Inventory host variables: `host_vars/`
   - Playbook variables: `vars:` section

3. **Facts** (discovered from hosts)
   - `ansible_facts` dictionary populated by `gather_facts`

4. **Registered Variables**
   - Variables assigned from task results: `register:`

5. **Jinja2 Expressions & Filters**
   - Runtime computed values

6. **Command-line Variables** (highest priority)
   - `ansible-playbook -e "var=value"`

**Strategic Implication**: This precedence enables progressive specialization—defaults provide sane values, group variables handle environment-specific configs, command-line overrides enable operational flexibility.

#### Collection & Role Architecture

**Collections** provide modular packaging:

```
my_collection/
├── README.md
├── galaxy.yml                    # Collection metadata, version, dependencies
├── roles/                        # Reusable roles
├── modules/                      # Custom modules
├── plugins/
│   ├── filters/                 # Custom Jinja2 filters
│   ├── inventory/               # Dynamic inventory plugins
│   ├── lookup/                  # Custom lookup functions
│   └── test/                    # Custom test plugins
└── meta/
    └── runtime.yml              # Module deprecations, versioning
```

**Roles** provide task organization:

```
my_role/
├── defaults/main.yml            # Default variables (lowest precedence)
├── vars/main.yml                # Role-specific variables (higher precedence)
├── files/                       # Static files to copy
├── templates/                   # Jinja2 templates
├── tasks/main.yml               # Role tasks
├── handlers/main.yml            # Handlers triggered by tasks
├── meta/main.yml                # Role metadata, dependencies
└── tests/                       # Test playbooks (optional)
```

This structure enforces a clear contract for role consumers: inputs (defaults/vars), outputs (handlers), and implementation (tasks).

### Important DevOps Principles

#### Immutability as Strategy

While traditional configuration management (Puppet, Chef) focus on converging mutable systems, Ansible enables both mutable and immutable approaches:

- **Mutable**: Use Ansible to continuously maintain infrastructure state (traditional CM)
- **Immutable**: Use Ansible to create infrastructure images/artifacts, deploy as immutable units (modern container/IaC approach)

**Best Practice**: In cloud-native architectures, use Ansible for infrastructure provisioning (mutable phase), but containerize applications as immutable images. This hybrid approach balances flexibility with reliability.

#### Separation of Concerns

Ansible's architecture encourages clear separation:

- **Infrastructure Provisioning Role**: Manages cloud resources (VMs, networks, storage)
- **Platform Configuration Role**: Installs runtime (Kubernetes, database engines)
- **Application Deployment Role**: Deploys business logic

This separation enables:
- Independent versioning of infrastructure vs. applications
- Reuse across projects
- Specialized team ownership
- Clear rollback boundaries

#### Configuration as Code

Infrastructure declared in version control enables:
- Change auditing (git history)
- Code review before deployment
- Reproducible deployments
- Disaster recovery through code recreation

**Ansible's Role**: Version-controlled playbooks declare infrastructure state, collections versioning ensures deterministic behavior.

#### Failure Recovery

Enterprise systems require robust failure handling:

- **Idempotent Tasks**: Tasks safe to retry without side effects
- **Handlers**: Deferred actions (service restart, cache flush) executed once at play end
- **Error Handling**: `failed_when`, `changed_when` define task success criteria
- **Execution Strategies**: Determine host failure response (stop all, continue, use serial execution)

**Strategic Pattern**: Combine `serial` execution with health checks to enable progressive rollout with automatic rollback on failure detection.

#### Auditability & Compliance

Production infrastructure requires audit trails:

- **Playbook Results**: JSON output captures what changed on each host
- **Registered Facts**: Module outputs available for logging
- **Custom Modules**: Can emit compliance telemetry
- **Handlers**: Trigger log shipping or alerting

**Enterprise Pattern**: Pipe Ansible JSON output to central logging (Splunk, ELK), create audit records for compliance frameworks (PCI, SOC2, HIPAA).

### Best Practices

#### 1. Roles Over Playbooks

❌ **Avoid**: Large monolithic playbooks with hardcoded tasks
```yaml
- hosts: all
  tasks:
    - name: Install Docker
      apt: name=docker.io
    - name: Configure Docker
      copy: src=daemon.json dest=/etc/docker/daemon.json
    # ... 50 more tasks in one file
```

✅ **Preferred**: Modular roles organized by function
```yaml
- hosts: all
  roles:
    - { role: docker_install, tags: ['docker'] }
    - { role: docker_configure, tags: ['docker'] }
    - { role: docker_validate, tags: ['docker'] }
```

**Why**: Roles enable reuse, testing, and clear contracts (inputs/outputs).

#### 2. Variable Strategy: Layers & Defaults

❌ **Avoid**: Variables scattered across multiple files with unclear precedence
```yaml
# In tasks:
    - name: Deploy app
      command: /opt/app/deploy.sh {{ app_version }}
      
# app_version defined in 5 different places—which wins?
```

✅ **Preferred**: Explicit variable layers with documented defaults
```yaml
# roles/app_deploy/defaults/main.yml
app_version: "1.0.0"                    # Conservative default
app_deploy_user: "appuser"
app_deployment_strategy: "rolling"

# roles/app_deploy/vars/main.yml
app_deploy_paths:
  bin: "/opt/app/bin"
  config: "/etc/app"
  
# group_vars/production/main.yml
app_version: "2.5.1"                    # Production override
app_deployment_strategy: "blue_green"
```

**Why**: Clear defaults enable role independence; explicit overrides prevent surprises.

#### 3. Idempotent Task Design

❌ **Not Idempotent**: Running multiple times causes problems
```yaml
- name: Create user
  shell: useradd -m {{ username }}      # Fails if user exists
```

✅ **Idempotent**: Repeatable without side effects
```yaml
- name: Create user
  user:
    name: "{{ username }}"
    shell: /bin/bash
    state: present                      # Module handles idempotence
```

**Why**: Infrastructure automation must be retry-safe. CI/CD pipelines often re-run operations; idempotent tasks enable this safely.

#### 4. Command vs. State Modules

❌ **Avoid**: Using `shell`/`command` modules for state management
```yaml
- name: Ensure service is running
  shell: service nginx status || service nginx start
```

✅ **Preferred**: State-specific modules
```yaml
- name: Ensure nginx is started
  systemd:
    name: nginx
    state: started
    enabled: yes
```

**Why**: State modules are idempotent and return structured results; shell commands are procedural and error-prone.

#### 5. Collection Versioning Strategy

❌ **Avoid**: Installing collections without version pinning
```yaml
# ansible.cfg
collections_paths = /opt/ansible/collections
# Collections auto-update, breaking old playbooks
```

✅ **Preferred**: Explicit version management
```yaml
# Collections specified in requirements.yml
collections:
  - name: community.aws
    version: ">=5.0.0,<6.0.0"
  - name: kubernetes.core
    version: "2.3.1"
    
# Playbook workflow includes version verification step
```

**Why**: Reproducible deployments require deterministic dependencies. Version ranges balance flexibility with stability.

#### 6. Execution Strategy Selection

❌ **Avoid**: Default linear strategy for all scenarios
```yaml
- hosts: all
  tasks:
    - name: Perform long operation
      command: migrate_database.sh
    # Waits for all hosts sequentially (slow)
```

✅ **Preferred**: Strategy matched to operation
```yaml
# For parallel, shorter operations: free strategy
- hosts: all
  strategy: free
  tasks: [...]

# For orchestrated rollout: serial + linear
- hosts: all
  serial: 2                            # Roll out 2 hosts at a time
  strategy: linear
  tasks: [...]
```

**Why**: Execution strategies dramatically impact performance and orchestration control. Match strategy to operation requirements.

#### 7. Custom Module When Needed

❌ **Avoid**: Complex logic in handlers/tasks
```yaml
- name: Configure complex state
  shell: |
    set -e
    state=$(curl -s https://api.example.com/state)
    if [ "$state" == "active" ]; then
      # 30 lines of bash logic
    fi
```

✅ **Preferred**: Custom module for complex logic
```yaml
- name: Configure complex state
  my_custom_module:
    state: configured
  # Module encapsulates logic, error handling, validation
```

**Why**: Custom modules are testable, reusable, and maintainable. Complex logic in YAML becomes unmaintainable.

### Common Misunderstandings

#### Misunderstanding #1: "Ansible is only for configuration management"

**Incorrect**: Ansible manages system configuration files like Puppet/Chef.

**Correct**: Ansible is an orchestration platform that can manage any state via modules. It's equally effective for infrastructure provisioning, application deployment, microservice orchestration, and compliance enforcement. The "CM" misconception limits thinking about Ansible's scope.

**Implication**: Senior engineers should architect Ansible as a central orchestration hub, not relegated to "config management" responsibilities.

#### Misunderstanding #2: "Variables defined everywhere are fine due to precedence"

**Incorrect**: Since Ansible has precedence rules, scattering variables across 10 files is acceptable.

**Correct**: While Ansible resolves variable conflicts via precedence, this creates maintenance nightmares. Senior deployments employ strict variable organization:
- Defaults in role `defaults/`
- Environment-specific in `group_vars/`
- Operational overrides on command line

Relying on precedence to resolve conflicts indicates poor architecture.

#### Misunderstanding #3: "Roles are just ways to organize playbooks"

**Incorrect**: Roles are a convenient file structure.

**Correct**: Roles define a contract between provider and consumer:
- **Interface**: `defaults/main.yml` defines inputs, `vars/main.yml` defines internal state
- **Behavior**: `tasks/main.yml` implements automation
- **Notifications**: `handlers/main.yml` defines observable side effects

Roles enable composition without coupling. Treating roles as mere file organization misses their architectural value.

#### Misunderstanding #4: "Collections are just plugin packages"

**Incorrect**: Collections are primarily for distributing custom plugins.

**Correct**: Collections are the primary distribution mechanism for Ansible content at enterprise scale. They include versioning, dependency management, documentation standards, and Galaxy integration. Collections enable organizations to package approved automation patterns for standardized deployment.

**Implication**: Organizations should develop internal collections for standardized infrastructure patterns, not scatter roles across playbooks.

#### Misunderstanding #5: "Async tasks are for long operations"

**Incorrect**: Use `async` whenever operations take time.

**Correct**: Async tasks are for operations where you need to:
- Poll external systems while tasks run
- Run multiple long operations in parallel
- Avoid blocking other plays
- Implement custom timeout logic

Using async for every long operation increases complexity. Many long operations are fine with linear execution if you've optimized orchestration.

#### Misunderstanding #6: "Custom modules are hard; just use shell modules"

**Incorrect**: Custom modules are complex; ansible-playbook can do anything.

**Correct**: Modern Ansible module development is straightforward. A Python module with error handling, structured output, and idempotency is more reliable than 50 lines of shell/Python in a task. Modules are testable, versionable, and composable.

**Implication**: When task logic exceeds 10 lines or requires robust error handling, custom module development is the professional choice.

---

## Roles & Collections

### Textual Deep Dive

#### Internal Working Mechanism

**Role Execution Model**:

When Ansible encounters a `roles:` directive, it performs the following sequence:

1. **Role Search**: Locates role in `roles_path` (default: `./roles/`, `/etc/ansible/roles/`, etc.)
2. **Meta Processing**: Executes dependencies declared in `meta/main.yml` first
3. **Variable Loading**: 
   - Loads defaults from `defaults/main.yml` (lowest precedence)
   - Loads vars from `vars/main.yml` (higher precedence)
4. **Task Execution**: Runs tasks from `tasks/main.yml`
5. **Handler Registration**: Registers handlers from `handlers/main.yml` for notification
6. **Pre/Post Hooks**: Executes `tasks/pre_tasks.yml` and `tasks/post_tasks.yml` if present

```
Role Invocation (in playbook)
    ↓
├─ Load meta/main.yml
│  └─ Process role dependencies recursively
├─ Load defaults/main.yml
├─ Load vars/main.yml
├─ Load files/ content (reference only)
├─ Load templates/ (reference only)
├─ Execute tasks/main.yml
│  ├─ Copy files/ contents to targets
│  ├─ Render templates/ with variables
│  └─ Execute module calls
├─ Register handlers/main.yml
└─ Complete
```

**Collection Architecture**:

Collections operate at a higher abstraction level than roles. They provide namespaced content:

```
Install Process:
$ ansible-galaxy collection install community.aws

Result:
~/.ansible/collections/ansible_collections/community/aws/
├── galaxy.yml (metadata, dependencies, versioning)
├── MANIFEST.json (file checksums, build info)
├── roles/
├── modules/
├── plugins/
│   ├── inventory/
│   ├── filter/
│   ├── lookup/
│   └── test/
└── docs/

Invocation in playbook:
  - community.aws.ec2:           # Fully qualified module name (FQCN)
  - name: My role
    import_role:
      name: community.aws.my_role # Collection-qualified role

Variable Scope:
  - Fully qualified names prevent namespace collision
  - Collections can depend on other collections (galaxy.yml)
  - Version constraints enable dependency management
```

#### Architecture Role

In enterprise infrastructure automation, Roles and Collections serve as the foundational architecture for code organization:

**Role Responsibilities**:
- **Unit of Reusability**: Smallest reusable automation component with clear interface
- **Abstraction Layer**: Hide implementation details behind a simple input/output contract
- **Idempotency Provider**: Ensure repeated execution is safe
- **Testing Boundary**: Define what can be independently tested

**Collection Responsibilities**:
- **Distribution Mechanism**: Package related roles, modules, plugins as versioned artifact
- **Namespace Management**: Prevent naming collisions when multiple teams contribute automation
- **Dependency Management**: Declare and resolve dependencies (other collections, minimum Ansible version)
- **Documentation Hub**: Centralize documentation, examples, changelog
- **Enterprise Registry**: Support internal/private Galaxy registries for compliance-controlled distribution

**Organizational Architecture Pattern**:

```
Enterprise Repository Structure:

ansible-infra/
├── collections/
│   └── internal/
│       └── myorg/
│           └── platform/
│               ├── galaxy.yml (namespace: myorg.platform)
│               ├── roles/
│               │   ├── kubernetes_node/
│               │   ├── vpc_provisioner/
│               │   └── monitoring_agent/
│               ├── modules/
│               │   └── custom_cloud_api/
│               └── plugins/
│                   └── filters/
│
├── playbooks/
│   ├── site.yml (main entry point)
│   ├── provision.yml (infrastructure provisioning)
│   ├── deploy.yml (application deployment)
│   └── configure/
│       ├── monitoring.yml
│       └── compliance.yml
│
├── inventory/
│   ├── hosts (static inventory)
│   ├── group_vars/
│   └── host_vars/
│
└── requirements.yml (external collections)
```

#### Production Usage Patterns

**Pattern 1: Multi-Environment Stack with Role Inheritance**

Organizations frequently need the same automation logic with environment-specific variations:

```yaml
# Playbook file: provision-web-tier.yml
---
- name: Provision web tier infrastructure
  hosts: localhost
  gather_facts: no
  vars:
    env: "{{ ansible_env | default('dev') }}"
  roles:
    - role: vpc_provisioner
      tags: [infrastructure, vpc]
      vars:
        vpc_cidr: "{{ vpc_cidrs[env] }}"
        
    - role: security_groups
      tags: [infrastructure, security]
      vars:
        allowed_ports: "{{ web_tier_ports[env] }}"
        
    - role: autoscaling_group
      tags: [infrastructure, compute]
      vars:
        min_capacity: "{{ asg_capacity[env].min }}"
        max_capacity: "{{ asg_capacity[env].max }}"

# group_vars/production/main.yml
vpc_cidrs:
  dev: "10.0.0.0/16"
  staging: "10.1.0.0/16"
  production: "10.2.0.0/16"

web_tier_ports:
  dev: [80, 443, 22]
  staging: [80, 443]
  production: [80, 443]

asg_capacity:
  dev: { min: 1, max: 3 }
  staging: { min: 2, max: 5 }
  production: { min: 3, max: 20 }
```

**Pattern 2: Composable Role Chain for Kubernetes**

Complex infrastructure often requires sequential role execution with conditional flow:

```yaml
# playbooks/k8s-upgrade.yml
---
- name: Kubernetes cluster rolling upgrade
  hosts: k8s_nodes
  gather_facts: yes
  serial: "{{ serial_count }}"
  
  pre_tasks:
    - name: Validate cluster health before upgrade
      import_role:
        name: k8s_health_check
      vars:
        required_healthy_percentage: 100

  roles:
    - role: k8s_node_drain
      tags: [upgrade, safety]
      when: inventory_hostname != groups['k8s_nodes'][0]
      # Don't drain first node (control plane)
      
    - role: k8s_node_upgrade
      tags: [upgrade]
      vars:
        upgrade_version: "{{ target_k8s_version }}"
        
    - role: k8s_node_uncordon
      tags: [upgrade, recovery]

  post_tasks:
    - name: Verify upgrade success
      import_role:
        name: k8s_health_check
      vars:
        required_healthy_percentage: 95
        
    - name: Notify upgrade completion
      nohup:
        command: "curl -X POST {{ slack_webhook }} -d 'Upgraded node {{ inventory_hostname }}'"
      when: slack_webhook is defined
```

**Pattern 3: Collection-Based Multi-Team Automation**

Organizations with multiple teams use collections to standardize and distribute automation:

```yaml
# requirements.yml
collections:
  - name: community.aws
    version: ">=5.0.0,<6.0.0"
  - name: myorg.platform
    version: "2.1.0"
    source: https://artifactory.internal/ansible
  - name: myorg.security
    version: ">=1.5.0"
    source: https://artifactory.internal/ansible
  - name: kubernetes.core
    version: "2.3.1"

# playbook using collection FQCN
---
- name: Deploy microservice
  hosts: k8s_cluster
  
  roles:
    - myorg.platform.k8s_namespace        # Fully qualified collection role
    - myorg.platform.helm_repository
    - kubernetes.core.helm                # Collection from public Galaxy
    
  tasks:
    - name: Create dashboard
      myorg.platform.dashboard_create:    # Collection module FQCN
        name: "{{ service_name }}"
        namespace: "{{ k8s_namespace }}"
        replicas: 3
```

#### DevOps Best Practices

**Practice 1: Role Dependency Management**

Explicit role dependencies in `meta/main.yml` document and enforce requirements:

```yaml
# roles/kubernetes_worker/meta/main.yml
---
dependencies:
  - role: common_hardening
    tags: [security]
    vars:
      security_level: strict
      
  - role: docker_runtime
    tags: [runtime]
    vars:
      docker_version: "{{ docker_version_min }}"
      
  - role: kernel_tuning
    tags: [performance]
    when: enable_performance_tuning | default(false)

# Benefits:
# - Declarative: readers understand role dependencies
# - Enforced: dependencies always loaded in correct order
# - Conditional: can gate dependencies on variables/conditions
```

**Practice 2: Role Input/Output Contract Definition**

Define explicit interfaces for role interaction:

```yaml
# roles/postgresql_backup/defaults/main.yml (INPUTS)
---
postgresql_backup_enabled: true
postgresql_backup_schedule: "0 2 * * *"           # Daily 2 AM
postgresql_backup_retention_days: 30
postgresql_backup_destination: "/backup/postgres"
postgresql_backup_compression: gzip               # gzip, bzip2, none
postgresql_backup_parallel_jobs: 4

# roles/postgresql_backup/vars/main.yml (INTERNAL STATE)
---
backup_db_user: "backup_user"
backup_script_path: "/usr/local/bin/pg-backup.sh"
backup_logfile: "/var/log/postgresql-backup.log"

# roles/postgresql_backup/tasks/main.yml emits facts (OUTPUTS)
- set_fact:
    postgresql_backup_status:
      enabled: "{{ postgresql_backup_enabled }}"
      last_backup_time: "{{ lookup('file', backup_logfile) | regex_search('[0-9]{4}-[0-9]{2}-[0-9]{2}') }}"
      last_backup_size: "{{ ansible_builtin.stat(path=postgresql_backup_destination).size }}"
      next_backup_time: "{{ backup_schedule }}"

# Consuming playbook benefits from clear contract:
- import_role:
    name: postgresql_backup
  vars:
    postgresql_backup_enabled: true
    postgresql_backup_retention_days: 90

- debug:
    msg: "Last backup: {{ postgresql_backup_status.last_backup_time }}"
```

**Practice 3: Collection Versioning Strategy**

Production systems require deterministic automation behavior:

```yaml
# requirements.yml - STRICT VERSION PINNING
collections:
  # Exact version for mission-critical content
  - name: myorg.platform
    version: "2.3.1"
    source: https://artifactory.internal/ansible
    
  # Version constraint for flexibility with safety
  - name: community.aws
    version: ">=5.2.0,<6.0.0"
    
  # Latest patch for frequently updated content
  - name: kubernetes.core
    version: ">=2.3.0,<2.4.0"
    
# Verification playbook ensures expected versions installed
---
- name: Verify collection versions
  hosts: localhost
  gather_facts: no
  tasks:
    - name: Get installed collections
      command: ansible-galaxy collection list --format json
      register: collection_check
      changed_when: false
      
    - name: Validate required versions
      assert:
        that:
          - item.version is version("2.3.1", "==")
        fail_msg: "Collection {{ item.name }} version mismatch"
      loop: "{{ collection_check.collections | selectattr('name', 'eq', 'myorg.platform') }}"
```

#### Common Pitfalls

**Pitfall 1: Tight Role Coupling**

❌ **Problematic**: Roles depend on specific inventory structure
```yaml
# roles/app_deploy/tasks/main.yml
- name: Deploy to web servers
  copy:
    src: app.jar
    dest: /opt/app/{{ groups['web_servers'][0] }}/app.jar
    # Directly references inventory group—tightly coupled
    # Breaks if group name changes
```

✅ **Solution**: Use role parameters instead
```yaml
# roles/app_deploy/defaults/main.yml
app_deploy_target_hosts: "{{ groups['web_servers'] }}"
app_deploy_user: appuser

# roles/app_deploy/tasks/main.yml
- name: Deploy application
  copy:
    src: app.jar
    dest: /opt/app/app.jar
    owner: "{{ app_deploy_user }}"
    
# Consuming playbook can override:
- import_role:
    name: app_deploy
  vars:
    app_deploy_target_hosts: "{{ groups['custom_app_tier'] }}"
```

**Pitfall 2: Circular Role Dependencies**

❌ **Problematic**: Role A depends on B, B imports A
```yaml
# roles/storage/meta/main.yml
dependencies:
  - role: networking          # OK

# roles/networking/meta/main.yml
dependencies:
  - role: storage             # CIRCULAR!
  
# Ansible hangs in dependency resolution
```

✅ **Solution**: Break cycles with ordering guarantees
```yaml
# Orchestrate layering at playbook level instead
- import_role:
    name: networking
    
- import_role:
    name: storage
    
# meta/main.yml now only includes shared dependencies
```

**Pitfall 3: Unversioned Collection Dependencies**

❌ **Problematic**: Missing version constraints
```yaml
# requirements.yml
collections:
  - name: community.aws       # No version specified
  # Auto-installs latest -> unpredictable behavior
```

✅ **Solution**: Explicit versioning
```yaml
# requirements.yml
collections:
  - name: community.aws
    version: "5.2.0"         # Deterministic
    
# Or with constraints for updates:
  - name: community.aws
    version: ">=5.0.0,<6.0.0" # Allows patch updates
```

**Pitfall 4: Role Variable Shadowing**

❌ **Problematic**: Same variable name at multiple precedence levels causes confusion
```yaml
# roles/app_config/defaults/main.yml
app_port: 8080

# roles/app_config/vars/main.yml
app_port: 9090

# group_vars/webservers.yml
app_port: 80

# Playbook
- import_role:
    name: app_config
    
# Which port is used? (answer: 80, but requires precedence knowledge)
```

✅ **Solution**: Prefix variables by scope/purpose
```yaml
# defaults/main.yml
app_config_default_port: 8080

# vars/main.yml
app_config_internal_port: 9090

# Explicit consumption
- name: Configure app
  template:
    src: app.conf.j2
    dest: /etc/app/config
  vars:
    app_listen_port: "{{ app_config_user_port | default(app_config_default_port) }}"
    # Clear which value is used
```

**Pitfall 5: Collection Namespace Confusion**

❌ **Problematic**: Using unqualified names
```yaml
# Which role? roles/ subdirectory or community.general?
- import_role:
    name: copy_files
    
tasks:
  - name: Copy config
    copy:                     # Which copy module?
      src: app.conf
      dest: /etc/app.conf
```

✅ **Solution**: Always use FQCN (Fully Qualified Collection Name)
```yaml
- import_role:
    name: myorg.platform.copy_files
    
tasks:
  - name: Copy config
    ansible.builtin.copy:     # Explicit builtin
      src: app.conf
      dest: /etc/app.conf
```

**Pitfall 6: Secrets Embedded in Role Defaults**

❌ **Insecure**: Hardcoded credentials
```yaml
# roles/database/defaults/main.yml
db_admin_user: admin
db_admin_password: SuperSecret123!      # EXPOSED IN REPO!
```

✅ **Solution**: External secret management
```yaml
# roles/database/defaults/main.yml
db_admin_user: admin
db_admin_password: "{{ vault_db_admin_password }}"

# Provide via ansible-vault or external secret manager
ansible-playbook -e "@vault.yml" site.yml

# Or with external secret lookup:
db_admin_password: "{{ lookup('hashi_vault', 'secret=data/db') }}"
```

### Practical Code Examples

**Example 1: Production Web Service Role**

```yaml
# roles/web_service/meta/main.yml
---
author: "Infrastructure Team"
company: "ACME Corp"
license: "MIT"
min_ansible_version: "2.9"

dependencies:
  - role: common_base
    tags: [bootstrap]
  - role: monitoring_agent
    vars:
      monitor_service_name: "{{ service_name }}"

argument_specs:
  main:
    short_description: Deploy production web service
    options:
      service_name:
        description: Service identifier
        type: str
        required: true
      service_port:
        description: Service listening port
        type: int
        default: 8080
      service_replicas:
        description: Number of service replicas
        type: int
        default: 3
      enable_ssl:
        description: Enable TLS/SSL
        type: bool
        default: true

# roles/web_service/defaults/main.yml
---
service_name: web-api
service_port: 8080
service_replicas: 3
service_user: svcuser
service_group: svcgroup
enable_ssl: true
ssl_cert_path: /etc/ssl/certs
ssl_key_path: /etc/ssl/private

service_log_level: INFO
service_log_path: /var/log/services/{{ service_name }}
service_health_check_path: /healthz
service_health_check_interval: 30

# roles/web_service/vars/main.yml
---
service_binary_path: /opt/services/{{ service_name }}/bin
service_config_path: /etc/services/{{ service_name }}
service_data_path: /var/lib/services/{{ service_name }}
service_systemd_unit: "{{ service_name }}.service"

# roles/web_service/tasks/main.yml
---
- name: Validate service requirements
  assert:
    that:
      - service_name != ''
      - service_port | int > 1024
      - service_replicas | int >= 1
    fail_msg: "Invalid service configuration"

- name: Create service user and group
  block:
    - name: Create service group
      group:
        name: "{{ service_group }}"
        state: present

    - name: Create service user
      user:
        name: "{{ service_user }}"
        group: "{{ service_group }}"
        shell: /usr/sbin/nologin
        home: "{{ service_data_path }}"
        state: present

- name: Create service directories
  file:
    path: "{{ item }}"
    state: directory
    owner: "{{ service_user }}"
    group: "{{ service_group }}"
    mode: "{{ item_mode }}"
  loop:
    - "{{ service_config_path }}"
    - "{{ service_data_path }}"
    - "{{ service_log_path }}"
  vars:
    item_mode: "0750"

- name: Deploy service binary
  copy:
    src: "{{ service_name }}-{{ service_version }}-amd64"
    dest: "{{ service_binary_path }}/{{ service_name }}"
    owner: "{{ service_user }}"
    group: "{{ service_group }}"
    mode: "0755"
  notify: restart service

- name: Deploy service configuration
  template:
    src: service.conf.j2
    dest: "{{ service_config_path }}/config.yml"
    owner: "{{ service_user }}"
    group: "{{ service_group }}"
    mode: "0640"
    backup: yes
  notify: restart service

- name: Configure TLS certificates
  block:
    - name: Copy certificate
      copy:
        src: "certs/{{ service_name }}.crt"
        dest: "{{ ssl_cert_path }}/{{ service_name }}.crt"
        owner: root
        group: "{{ service_group }}"
        mode: "0640"
      when: enable_ssl

    - name: Copy private key
      copy:
        src: "certs/{{ service_name }}.key"
        dest: "{{ ssl_key_path }}/{{ service_name }}.key"
        owner: root
        group: "{{ service_group }}"
        mode: "0600"
      when: enable_ssl
  notify: restart service

- name: Deploy systemd unit file
  template:
    src: systemd.service.j2
    dest: "/etc/systemd/system/{{ service_systemd_unit }}"
    owner: root
    group: root
    mode: "0644"
  notify:
    - reload systemd
    - restart service

- name: Start and enable service
  systemd:
    name: "{{ service_systemd_unit }}"
    state: started
    enabled: yes
    daemon_reload: yes

- name: Verify service health
  uri:
    url: "http{% if enable_ssl %}s{% endif %}://localhost:{{ service_port }}{{ service_health_check_path }}"
    method: GET
    status_code: 200
  retries: 5
  delay: 10
  register: health_check

- name: Register monitoring
  set_fact:
    service_deployed:
      name: "{{ service_name }}"
      port: "{{ service_port }}"
      ssl_enabled: "{{ enable_ssl }}"
      replicas: "{{ service_replicas }}"
      user: "{{ service_user }}"
      status: "running"
      health_check_status: "{{ health_check.status }}"

# roles/web_service/handlers/main.yml
---
- name: restart service
  systemd:
    name: "{{ service_systemd_unit }}"
    state: restarted

- name: reload systemd
  systemd:
    daemon_reload: yes

# roles/web_service/templates/systemd.service.j2
[Unit]
Description={{ service_name }} Web Service
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User={{ service_user }}
Group={{ service_group }}
WorkingDirectory={{ service_data_path }}
ExecStart={{ service_binary_path }}/{{ service_name }} --config {{ service_config_path }}/config.yml
Restart=on-failure
RestartSec=10s
StandardOutput=journal
StandardError=journal
SyslogIdentifier={{ service_name }}

# roles/web_service/templates/service.conf.j2
server:
  name: {{ service_name }}
  listen: 0.0.0.0
  port: {{ service_port }}
  ssl: {{ enable_ssl | lower }}
  {% if enable_ssl %}
  cert_path: {{ ssl_cert_path }}/{{ service_name }}.crt
  key_path: {{ ssl_key_path }}/{{ service_name }}.key
  {% endif %}

logging:
  level: {{ service_log_level }}
  file: {{ service_log_path }}/{{ service_name }}.log

health_check:
  enabled: true
  interval: {{ service_health_check_interval }}
  path: {{ service_health_check_path }}
```

**Example 2: Collection with Custom Module**

```yaml
# collections/myorg/platform/galaxy.yml
---
namespace: myorg
name: platform
version: 2.1.0
license: [Apache-2.0]
description: Production infrastructure automation collection
authors:
  - Infrastructure Team <infra@acme.com>
maintainers:
  - Senior DevOps Engineers

dependencies:
  community.aws: ">=5.0.0,<6.0.0"
  community.kubernetes: ">=2.0.0"

# collections/myorg/platform/roles/vpc_provisioner/defaults/main.yml
---
vpc_name: "{{ cluster_name }}-vpc"
vpc_cidr: "10.0.0.0/16"
vpc_azs: []                              # Auto-detect from region if empty
vpc_public_subnets: ["10.0.1.0/24", "10.0.2.0/24"]
vpc_private_subnets: ["10.0.11.0/24", "10.0.12.0/24"]
vpc_nat_gateway_count: 1
vpc_enable_dns: true
vpc_tags: {}

# collections/myorg/platform/modules/query_aws_regions.py
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from ansible.module_utils.basic import AnsibleModule
import boto3

def main():
    module = AnsibleModule(
        argument_spec=dict(
            region_filter=dict(type='str', default='us-*'),
            attributes=dict(type='list', default=['RegionName', 'Endpoint'])
        )
    )
    
    try:
        ec2 = boto3.client('ec2', region_name='us-east-1')
        regions = ec2.describe_regions()['Regions']
        
        filtered_regions = []
        for region in regions:
            region_name = region.get('RegionName', '')
            if '*' in module.params['region_filter']:
                import fnmatch
                if fnmatch.fnmatch(region_name, module.params['region_filter']):
                    filtered_regions.append(region)
            else:
                if region_name == module.params['region_filter']:
                    filtered_regions.append(region)
        
        module.exit_json(
            changed=False,
            regions=filtered_regions,
            count=len(filtered_regions)
        )
        
    except Exception as e:
        module.fail_json(msg=str(e))

if __name__ == '__main__':
    main()

# collections/myorg/platform/roles/vpc_provisioner/tasks/main.yml
---
- name: Query available AWS regions
  myorg.platform.query_aws_regions:
    region_filter: "{{ region_pattern | default('us-*') }}"
  register: available_regions

- name: Select AZs if not specified
  set_fact:
    vpc_azs: "{{ available_regions.regions | map(attribute='RegionName') | list }}"
  when: vpc_azs | length == 0

- name: Create VPC
  amazon.aws.ec2_vpc_net:
    name: "{{ vpc_name }}"
    cidr_block: "{{ vpc_cidr }}"
    dns_hostnames: "{{ vpc_enable_dns }}"
    state: present
    tags: "{{ vpc_tags }}"
  register: vpc_result

- name: Create public subnets
  amazon.aws.ec2_vpc_subnet:
    vpc_id: "{{ vpc_result.vpc.id }}"
    cidr: "{{ item }}"
    az: "{{ vpc_azs[idx] }}"
    state: present
    tags:
      Name: "{{ vpc_name }}-public-{{ idx }}"
      Tier: Public
  loop: "{{ vpc_public_subnets }}"
  loop_control:
    index_var: idx
  register: public_subnets

- name: Create private subnets
  amazon.aws.ec2_vpc_subnet:
    vpc_id: "{{ vpc_result.vpc.id }}"
    cidr: "{{ item }}"
    az: "{{ vpc_azs[idx] }}"
    state: present
    tags:
      Name: "{{ vpc_name }}-private-{{ idx }}"
      Tier: Private
  loop: "{{ vpc_private_subnets }}"
  loop_control:
    index_var: idx
  register: private_subnets

- name: Create Internet Gateway
  amazon.aws.ec2_vpc_igw:
    vpc_id: "{{ vpc_result.vpc.id }}"
    state: present
    tags:
      Name: "{{ vpc_name }}-igw"
  register: igw

- name: Create NAT gateways
  block:
    - name: Allocate Elastic IPs
      amazon.aws.ec2_eip:
        domain: vpc
        state: present
        tags:
          Name: "{{ vpc_name }}-nat-eip-{{ idx }}"
      loop: "{{ range(0, vpc_nat_gateway_count) | list }}"
      loop_control:
        index_var: idx
      register: eips

    - name: Create NAT gateways
      amazon.aws.ec2_vpc_nat_gateway:
        subnet_id: "{{ public_subnets.results[idx].subnet.id }}"
        allocation_id: "{{ eips.results[idx].allocation_id }}"
        state: present
      loop: "{{ range(0, vpc_nat_gateway_count) | list }}"
      loop_control:
        index_var: idx
      register: nat_gateways

- name: Set VPC facts
  set_fact:
    vpc_provisioned:
      vpc_id: "{{ vpc_result.vpc.id }}"
      vpc_cidr: "{{ vpc_result.vpc.cidr_block }}"
      public_subnet_ids: "{{ public_subnets.results | map(attribute='subnet.id') | list }}"
      private_subnet_ids: "{{ private_subnets.results | map(attribute='subnet.id') | list }}"
      igw_id: "{{ igw.internet_gateway.internet_gateway_id }}"
      nat_gateway_ids: "{{ nat_gateways.results | map(attribute='nat_gateway_id') | list }}"
```

---

## Variables & Templating

### Textual Deep Dive

#### Internal Working Mechanism

**Variable Resolution Pipeline**:

When Ansible executes a task containing variable references (e.g., `"{{ my_var }}")`), it performs multi-stage resolution:

```
1. Variable Reference Detection
   └─ Parse {{ variable_name }} syntax in task YAML

2. Scope Resolution (in order of precedence)
   ├─ Extra vars from command line (highest priority)
   ├─ Set facts registered from tasks
   ├─ Role vars (role-specific)
   ├─ Block vars (block-scoped)
   ├─ Play vars (play-scoped)
   ├─ Task vars (task-local)
   ├─ Registered variables (from previous tasks)
   ├─ Inventory host_vars (specific host)
   ├─ Inventory group_vars (group membership)
   ├─ Role role_vars (role internal)
   ├─ Connection vars
   ├─ Facts discovered from target
   └─ Role defaults (lowest priority)

3. Jinja2 Template Rendering
   ├─ Parse Jinja2 syntax (filters, conditionals, loops)
   ├─ Execute Jinja2 expressions
   ├─ Evaluate conditionals (when:, if/else)
   └─ Return rendered string

4. Type Coercion
   ├─ Detect intended type (string, int, list, dict, bool)
   ├─ Convert from YAML representation
   └─ Validate type consistency

5. Filtering & Post-Processing
   ├─ Apply Ansible filters (| default, | length, etc.)
   ├─ Custom filter execution
   └─ Return final value
```

**Variable Types in Ansible**:

```
Scalar Variables:
  string_var: "value"              # String
  int_var: 42                      # Integer
  float_var: 3.14                  # Float
  bool_var: true                   # Boolean
  null_var: null                   # Null/None

Collection Variables:
  list_var: [1, 2, 3]             # List (ordered, indexed)
  dict_var:
    key1: value1
    key2: value2                  # Dictionary (key-value pairs)

Complex Variables:
  mixed_var:
    nested_list: [1, "two", 3]
    nested_dict:
      deep_key: deep_value        # Nested structures

Variable References:
  uses_other: "{{ other_var }}"
  interpolated: "prefix_{{ my_var }}_suffix"
  dotted_access: "{{ dict_var.key1 }}"
  indexed_access: "{{ list_var[0] }}"
```

**Jinja2 Templating Engine Integration**:

Ansible uses Jinja2 templating language for dynamic value computation:

```jinja2
{# Basic variable substitution #}
Server name: {{ server_name }}

{# Conditional logic #}
{% if environment == 'production' %}
  Replica count: 10
{% elif environment == 'staging' %}
  Replica count: 3
{% else %}
  Replica count: 1
{% endif %}

{# Loops #}
Open ports:
{% for port in open_ports %}
  - {{ port }}
{% endfor %}

{# Filters (transformations) #}
Uppercase: {{ server_name | upper }}
List length: {{ servers | length }}
Default value: {{ optional_var | default('NA') }}
Type check: {{ var_to_check | string }}

{# Complex expressions #}
Calculated value: {{ (base_cpu * num_instances) + overhead }}
Conditional default: {{ config_value if config_value is defined else 'default' }}

{# Set facts with Jinja2 #}
{% set derived_value = (item.cpu * 2) + item.memory %}
Calculated: {{ derived_value }}
```

#### Architecture Role

Variables and templating form the abstraction and parameterization layer in Ansible architecture:

**Position in Infrastructure Automation Stack**:

```
┌────────────────────────────────────────────────┐
│  Playbook Logic (conditional execution)        │
├────────────────────────────────────────────────┤
│  Jinja2 Templating (value computation)         │
├────────────────────────────────────────────────┤
│  Variables (data layer for automation)         │
├────────────────────────────────────────────────┤
│  Inventory (host definitions)                  │
├────────────────────────────────────────────────┤
│  Modules (execution primitives)                │
└────────────────────────────────────────────────┘

Variables enable:
• Parameterization: Same playbook behavior varies by input
• Multi-environment: Single codebase, different deployments
• Derived data: Computed values from base inputs
• Conditional logic: Branch execution based on variables
• Templating: Generate files/configs from data
```

#### Production Usage Patterns

**Pattern 1: Environment-Based Configuration Layering**

Organizations separate base configuration from environment-specific overrides:

```yaml
# Directory structure
inventory/
├── hosts                          # Static inventory
├── group_vars/
│   ├── all/
│   │   ├── common.yml            # Applied to all groups
│   │   └── security.yml          # Global security policies
│   ├── aws_us_east_1/
│   │   └── main.yml              # Region-specific vars
│   ├── dev/
│   │   ├── main.yml              # Dev environment config
│   │   └── secrets.yml           # Dev secrets (vault)
│   ├── staging/
│   │   └── main.yml              # Staging config
│   └── production/
│       └── main.yml              # Production config (encrypted)
└── host_vars/
    ├── web_01.yaml              # Web server 01 specifics
    └── db_primary.yaml          # Primary DB specifics

# group_vars/all/common.yml
---
organization: acme
deploy_user: deploy
package_manager: apt            # Or yum, etc.
timezone: UTC
ntp_servers: ["0.pool.ntp.org", "1.pool.ntp.org"]

# group_vars/dev/main.yml
---
environment: development
log_level: DEBUG
enable_debug_tools: true
db_backup_frequency: daily
replica_count: 1
cache_ttl: 300              # 5 minutes

# group_vars/production/main.yml
---
environment: production
log_level: WARNING
enable_debug_tools: false
db_backup_frequency: hourly
replica_count: 5
cache_ttl: 3600             # 1 hour

# Playbook invoces with environment vars
- name: Configure application
  hosts: all
  gather_facts: yes
  
  roles:
    - role: app_config
      vars:
        app_log_level: "{{ log_level }}"
        app_environment: "{{ environment }}"
        app_replicas: "{{ replica_count }}"
        
# Invocation determines environment:
ansible-playbook playbook.yml -i inventory/ -l dev
# Uses dev variables

ansible-playbook playbook.yml -i inventory/ -l production
# Uses production variables
```

**Pattern 2: Dynamic Configuration with Jinja2 Templating**

Templates generate files from variable data without hardcoding:

```yaml
# roles/nginx_config/defaults/main.yml
nginx_worker_processes: "auto"
nginx_worker_connections: 1024
nginx_keepalive_timeout: 65
nginx_gzip: on
nginx_gzip_types: "text/plain text/css text/xml text/javascript application/json"
nginx_ssl_protocols: "TLSv1.2 TLSv1.3"
nginx_ssl_ciphers: "ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256"

upstream_servers:
  - name: backend_pool
    servers: []                    # Populated by playbook
  - name: cache_pool
    servers: []

# roles/nginx_config/tasks/main.yml
---
- name: Query backend servers from inventory
  set_fact:
    backend_servers: "{{ groups['backend'] | map(attribute='ansible_default_ipv4.address') | list }}"

- name: Build upstream configuration
  set_fact:
    upstream_servers:
      - name: backend_pool
        servers: "{{ backend_servers | map('regex_replace', '^(.*)$', '\\1:8080') | list }}"

- name: Deploy nginx configuration
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
    backup: yes
  notify: reload nginx

# roles/nginx_config/templates/nginx.conf.j2
user www-data;
worker_processes {{ nginx_worker_processes }};
pid /run/nginx.pid;

events {
    worker_connections {{ nginx_worker_connections }};
    multi_accept on;
    use epoll;
}

http {
    # Basic settings
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout {{ nginx_keepalive_timeout }};
    types_hash_max_size 2048;
    
    # Gzip compression
    gzip {{ nginx_gzip | lower }};
    gzip_vary on;
    gzip_proxied any;
    gzip_types {{ nginx_gzip_types }};
    
    # SSL configuration
    ssl_protocols {{ nginx_ssl_protocols }};
    ssl_ciphers {{ nginx_ssl_ciphers }};
    ssl_prefer_server_ciphers on;
    
    # Upstream pools
    {% for pool in upstream_servers %}
    upstream {{ pool.name }} {
        {% for server in pool.servers %}
        server {{ server }};
        {% endfor %}
    }
    {% endfor %}
    
    # Virtual hosts
    include /etc/nginx/conf.d/*.conf;
}
```

**Pattern 3: Multi-Environment Secret Management**

Separating secrets by environment and protecting them:

```yaml
# ansible.cfg
[defaults]
vault_identity_list = prod@./prod_id, dev@./dev_id

# Structure
inventory/
├── group_vars/
│   ├── dev/
│   │   ├── main.yml (unencrypted)
│   │   └── vault.yml (encrypted with dev key)
│   └── production/
│       ├── main.yml (unencrypted)
│       └── vault.yml (encrypted with prod key)

# group_vars/production/main.yml (PUBLIC)
---
environment: production
db_host: rds-prod.us-east-1.rds.amazonaws.com

# group_vars/production/vault.yml (ENCRYPTED)
---
db_username: "{{ vault_db_prod_username }}"
db_password: "{{ vault_db_prod_password }}"
api_key: "{{ vault_api_key_prod }}"
ssl_cert_path: "{{ vault_ssl_cert_prod }}"

# Create vault file
ansible-vault create --vault-id prod@./prod_id inventory/group_vars/production/vault.yml

# Playbook references transparently
---
- hosts: production
  tasks:
    - name: Configure database
      postgresql_user:
        name: "{{ db_username }}"
        password: "{{ db_password }}"
        # Variables resolve regardless of encryption

# Invoke with vault password
ansible-playbook playbook.yml --vault-id prod@prompt
# User prompted for vault password during execution
```

#### DevOps Best Practices

**Practice 1: Variable Naming Conventions**

Establish consistent naming patterns for discoverability and maintenance:

```yaml
# Conventions
# <scope>_<function>_<attribute>

# Global scope (applies to all hosts)
global_ntp_server: "0.pool.ntp.org"
global_timezone: "UTC"

# Role scope (prefixed with role name)
nginx_worker_processes: 4
nginx_worker_connections: 1024
nginx_gzip_enabled: true

# Environment scope
dev_replica_count: 1
staging_replica_count: 2
prod_replica_count: 5

# Application scope
app_service_port: 8080
app_database_host: "localhost"

# Boolean naming (is_/enable_)
is_debug_enabled: false
enable_ssl: true
enable_backup: true

# List/dict naming (plural for collections)
allowed_ports: [22, 80, 443]
server_configs: { web: 8080, api: 9000 }

Benefits:
- Clear scope from prefix
- Easy grep for related variables
- Reduces collisions
- Self-documenting code
```

**Practice 2: Document Variable Intent**

Add structured documentation to variable definitions:

```yaml
# roles/app_deploy/defaults/main.yml with documentation
---
# Application deployment version
# Impact: Which version of application binary is deployed
# Precedence: Can be overridden per environment
app_version: "1.0.0"

# Deployment strategy
# Options: rolling, blue_green, canary
# Default: rolling (standard for web services)
# Note: blue_green requires separate environment
deploy_strategy: rolling

# Health check configuration
# Timeout before considering service unhealthy
# Unit: seconds
# Production recommendation: 30-60 seconds
health_check_timeout: 30

# Number of parallel deployments
# Impact: Higher = faster but risks resource exhaustion
# Range: 1 (serial) to inventory_size (parallel)
# Production recommendation: 2-3 in production
deploy_parallel_tasks: 2

# Advanced: Custom filtering function
# Used for: Complex condition evaluation
# Example: "{{ servers | select('match', 'prod-.*') }}"
# Warning: Can impact playbook performance if complex
custom_filter_expression: ""

# Usage in documentation
module:
  description: |
    Deploy application using specified strategy.
    
    Variables:
      app_version: Application semantic version (e.g., 1.2.3)
      deploy_strategy: Deployment approach (rolling, blue_green, canary)
      health_check_timeout: Health check timeout in seconds
```

**Practice 3: Use Jinja2 Filters for Data Transformation**

Leverage built-in and custom filters to compute derived values:

```yaml
# Commonly used Jinja2 filters in Ansible

# Type/existence checks
value: "{{ user_input | default('fallback') }}"
is_string: "{{ value is string }}"
is_defined: "{{ value is defined }}"
is_none: "{{ value is none }}"

# String operations
uppercase: "{{ name | upper }}"
lowercase: "{{ name | lower }}"
title_case: "{{ name | title }}"
truncated: "{{ long_string | truncate(10) }}"
regex_extract: "{{ hostname | regex_search('prod-(.*)') }}"

# List operations
unique_items: "{{ list_var | unique }}"
sorted_list: "{{ list_var | sort }}"
reversed: "{{ list_var | reverse }}"
filtered: "{{ list_var | select('match', 'pattern') | list }}"
flattened: "{{ nested_list | flatten }}"
grouped: "{{ list_var | groupby('type') }}"

# Math operations
incremented: "{{ counter | int + 1 }}"
multiplied: "{{ base_cpu | int * num_hosts }}"
min_value: "{{ [10, 5, 20] | min }}"
max_value: "{{ [10, 5, 20] | max }}"

# Dictionary operations
keys: "{{ config | list }}"                 # Get dict keys
values: "{{ config | dict2items }}"        # Convert to key/value pairs
merged: "{{ dict1 | combine(dict2) }}"     # Merge dicts

# Date/time operations
timestamp: "{{ now | strftime('%Y-%m-%d') }}"
iso8601: "{{ lookup('pipe', 'date -u +%Y-%m-%dT%H:%M:%SZ') }}"

# Custom filter example
# plugins/filter_plugins/custom_filters.py
def port_range(start, end):
    """Generate list of ports in range"""
    return list(range(int(start), int(end)+1))

class FilterModule:
    def filters(self):
        return {'port_range': port_range}

# Usage
ports: "{{ range_start | port_range(range_end) }}"
# Result: [8000, 8001, 8002, ...8100]
```

**Practice 4: Avoid Variable Shadowing and Confusion**

Prevent variables with same name at different precedence levels:

```yaml
# AVOID: Same variable name at multiple levels
# defaults/main.yml
app_port: 8080

# vars/main.yml  
app_port: 9090

# group_vars/production.yml
app_port: 80

# Which value is used? (Answer: 80, but requires precedence knowledge)

# PREFERRED: Distinct names by role/component
# defaults/main.yml (base configuration)
app_config_default_port: 8080
app_config_default_timeout: 30

# group_vars/all.yml (global organizational standard)
org_standard_port: 8080
org_standard_timeout: 60

# group_vars/production.yml (environment override)
env_production_port: 80
env_production_timeout: 120

# Task usage is explicit:
- name: Configure application
  template:
    src: app.conf.j2
    dest: /etc/app.conf
  vars:
    # Priority order clearly declared
    configured_port: "{{ env_production_port | default(org_standard_port, true) | default(app_config_default_port, true) }}"
    configured_timeout: "{{ env_production_timeout | default(org_standard_timeout, true) | default(app_config_default_timeout, true) }}"
```

#### Common Pitfalls

**Pitfall 1: Complex Jinja2 Logic in Templates**

❌ **Problematic**: Business logic in template files
```jinja2
{# roles/app_config/templates/app.conf.j2 - WRONG #}
{% set replicas = num_hosts * cpu_count / 2 %}
{% if replicas > 100 %}
  max_replicas: 100
{% elif replicas < 5 %}
  max_replicas: 5
{% else %}
  max_replicas: {{ replicas }}
{% endif %}
{# Hard to test, maintain, and understand #}
```

✅ **Solution**: Compute in playbook, pass to template
```yaml
# roles/app_config/tasks/main.yml
- name: Calculate optimal replicas
  set_fact:
    calculated_replicas: "{{ [100, [5, (num_hosts | int * cpu_count | int / 2) | int] | max] | min }}"

# roles/app_config/templates/app.conf.j2
max_replicas: {{ calculated_replicas }}

# Benefits:
# - Testable in playbook context
# - Reusable logic
# - Clear variable dependency
```

**Pitfall 2: Hardcoded Values Instead of Variables**

❌ **Problematic**: Environment-specific hardcoding
```yaml
- name: Create S3 bucket
  amazon.aws.s3_bucket:
    name: "mycompany-data-prod"      # Hardcoded—can't reuse playbook
    region: "us-east-1"               # Hardcoded region
```

✅ **Solution**: Externalize as variables
```yaml
# defaults/main.yml
aws_s3_bucket_name: "{{ org_name }}-data-{{ environment }}"
aws_region: "us-east-1"

# group_vars/production.yml
aws_s3_bucket_name: "mycompany-data-prod"
aws_region: "us-east-1"

# group_vars/staging.yml
aws_s3_bucket_name: "mycompany-data-stg"
aws_region: "us-west-2"

- name: Create S3 bucket
  amazon.aws.s3_bucket:
    name: "{{ aws_s3_bucket_name }}"
    region: "{{ aws_region }}"
    # Reuse same playbook across environments
```

**Pitfall 3: Leaking Variables Across Plays**

❌ **Problematic**: Variable pollution across plays
```yaml
- name: Play 1
  hosts: webservers
  tasks:
    - set_fact:
        temporary_var: "value1"

- name: Play 2
  hosts: databases
  tasks:
    - debug:
        msg: "{{ temporary_var }}"      # Variable from different play—confusing
```

✅ **Solution**: Use play-scoped variables
```yaml
- name: Play 1
  hosts: webservers
  vars:
    play_specific_var: "value1"
  tasks:
    - set_fact:
        play_result: "{{ play_specific_var }}"

- name: Play 2
  hosts: databases
  vars:
    play_specific_var: "value2"
  tasks:
    - debug:
        msg: "{{ play_specific_var }}"    # Different across plays
```

**Pitfall 4: Undefined Variable References**

❌ **Problematic**: Referencing undefined variables causes silent failures
```yaml
- name: Deploy application
  template:
    src: app.conf.j2
    dest: /etc/app.conf
  # If app_version is not defined, template renders without value
  # Task succeeds but config is corrupted
```

✅ **Solution**: Explicit validation and defaults
```yaml
- name: Validate required variables
  assert:
    that:
      - app_version is defined and app_version != ""
      - app_config_path is defined and app_config_path != ""
    fail_msg: "Required variables not defined"

- name: Deploy application
  template:
    src: app.conf.j2
    dest: "{{ app_config_path }}/app.conf"
  # Template now guaranteed to have required variables
```

**Pitfall 5: Mixing Encrypted and Unencrypted Secrets**

❌ **Problematic**: Secrets in unencrypted files
```yaml
# group_vars/production.yml (unencrypted in repo!)
---
db_password: "SuperSecret123"           # EXPOSED!
api_key: "sk_live_abc123def456"        # EXPOSED!
```

✅ **Solution**: Encrypt sensitive data
```yaml
# group_vars/production/main.yml (unencrypted)
---
db_host: "rds-prod.amazonaws.com"
api_endpoint: "https://api.service.com"

# group_vars/production/vault.yml (encrypted via ansible-vault)
---
db_password: !vault |
  $ANSIBLE_VAULT;1.1;AES256;prod
  ...encrypted data...

# Playbook includes both transparently
- hosts: production
  tasks:
    - name: Configure database
      postgresql_user:
        name: dbuser
        password: "{{ db_password }}"    # Resolves from vault.yml
```

### Practical Code Examples

**Example: Kubernetes Deployment with Templating**

```yaml
# playbook variables
---
- name: Deploy Kubernetes workload
  hosts: k8s_cluster
  gather_facts: no
  
  vars:
    # Base configuration
    app_name: web-api
    app_namespace: production
    app_replicas: 3
    app_port: 8080
    
    # Environment-based overrides
    env_vars:
      dev:
        replicas: 1
        resource_limit_cpu: "500m"
        resource_request_cpu: "100m"
      staging:
        replicas: 2
        resource_limit_cpu: "1000m"
        resource_request_cpu: "500m"
      production:
        replicas: 5
        resource_limit_cpu: "2000m"
        resource_request_cpu: "1000m"
  
  roles:
    - role: k8s_namespace
    - role: k8s_deployment
    
# roles/k8s_deployment/tasks/main.yml
---
- name: Load environment-specific configuration
  set_fact:
    effective_replicas: "{{ env_vars[environment]['replicas'] }}"
    effective_cpu_limit: "{{ env_vars[environment]['resource_limit_cpu'] }}"
    effective_cpu_request: "{{ env_vars[environment]['resource_request_cpu'] }}"

- name: Create deployment from template
  kubernetes.core.k8s:
    state: present
    namespace: "{{ app_namespace }}"
    definition: "{{ lookup('template', 'deployment.yml.j2') }}"

# roles/k8s_deployment/templates/deployment.yml.j2
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ app_name }}
  namespace: {{ app_namespace }}
  labels:
    app: {{ app_name }}
    environment: {{ environment }}
spec:
  replicas: {{ effective_replicas }}
  selector:
    matchLabels:
      app: {{ app_name }}
  template:
    metadata:
      labels:
        app: {{ app_name }}
        version: "{{ app_version }}"
    spec:
      containers:
      - name: {{ app_name }}
        image: "{{ docker_registry }}/{{ app_name }}:{{ app_version }}"
        ports:
        - containerPort: {{ app_port }}
        env:
        {% for key, value in app_environment_vars.items() %}
        - name: {{ key | upper }}
          value: "{{ value }}"
        {% endfor %}
        resources:
          limits:
            cpu: {{ effective_cpu_limit }}
            memory: "{{ env_vars[environment]['memory_limit'] | default('1Gi') }}"
          requests:
            cpu: {{ effective_cpu_request }}
            memory: "{{ env_vars[environment]['memory_request'] | default('256Mi') }}"
        livenessProbe:
          httpGet:
            path: /healthz
            port: {{ app_port }}
          initialDelaySeconds: 30
          periodSeconds: 10
      affinity:
        podAntiAffinity:
          {% if environment == 'production' %}
          requiredDuringSchedulingIgnoredDuringExecution:
          {% else %}
          preferredDuringSchedulingIgnoredDuringExecution:
          {% endif %}
          - labelSelector:
              matchExpressions:
              - key: app
                operator: In
                values:
                - {{ app_name }}
            topologyKey: kubernetes.io/hostname
```

**Example: Multi-Region Cloud Configuration**

```yaml
# group_vars/all/regions.yml
---
regions:
  us_east:
    name: us-east-1
    azs: [us-east-1a, us-east-1b, us-east-1c]
    vpc_cidr: 10.0.0.0/16
    nat_gateways: 3
    
  us_west:
    name: us-west-2
    azs: [us-west-2a, us-west-2b, us-west-2c]
    vpc_cidr: 10.1.0.0/16
    nat_gateways: 2
    
  eu_west:
    name: eu-west-1
    azs: [eu-west-1a, eu-west-1b, eu-west-1c]
    vpc_cidr: 10.2.0.0/16
    nat_gateways: 3

# playbook
---
- name: Deploy multi-region infrastructure
  hosts: localhost
  gather_facts: no
  
  tasks:
    - name: Deploy to each region
      include_tasks: deploy_region.yml
      loop_control:
        loop_var: current_region
      loop: "{{ regions.values() | list }}"
      
    - name: Set derived facts
      set_fact:
        all_vpcs: "{{ regions | dict2items | map(attribute='value.vpc_cidr') | list }}"
        dns_endpoints: |
          {%- set endpoints = [] -%}
          {%- for region in regions.values() -%}
            {%- set _ = endpoints.append(region.name + '.internal') -%}
          {%- endfor -%}
          {{- endpoints -}}

# deploy_region.yml
---
- name: Deploy region infrastructure
  block:
    - name: Create VPC in {{ current_region.name }}
      amazon.aws.ec2_vpc_net:
        name: "vpc-{{ current_region.name }}"
        cidr_block: "{{ current_region.vpc_cidr }}"
        region: "{{ current_region.name }}"
        
    - name: Create subnets in AZs
      amazon.aws.ec2_vpc_subnet:
        vpc_id: "{{ vpc_result.vpc.id }}"
        cidr: "{{ current_region.vpc_cidr.split('/')[0].rsplit('.', 1)[0] }}.{{ idx }}.0/24"
        az: "{{ az }}"
      loop: "{{ current_region.azs }}"
      loop_control:
        index_var: idx
        loop_var: az
```

---

## Ansible Modules & Custom Modules

### Textual Deep Dive

#### Internal Working Mechanism

**Module Execution Pipeline**:

When Ansible executes a module call, it performs the following sequence:

```
1. Module Resolution
   ├─ Search for module in collections (FQCN resolution)
   ├─ Search in built-in modules
   ├─ Search in library paths
   └─ Fail if module not found

2. Argument Processing
   ├─ Parse module arguments from task YAML
   ├─ Apply defaults from module spec (if YAML present)
   ├─ Validate argument types
   ├─ Check required arguments
   └─ Warning on deprecated/removed arguments

3. Task Preparation
   ├─ Render Jinja2 in argument values
   ├─ Determine if module has changed vs. check modes
   ├─ Decide execution target (local or remote host)
   └─ Set up asyncronous wrapper if async specified

4. Module Transfer
   ├─ For remote modules:
   │   ├─ Create temporary directory on target
   │   ├─ Transfer module code and libraries
   │   ├─ Inject module arguments as JSON
   │   └─ Set proper permissions
   └─ For local modules: run from control node

5. Module Execution
   ├─ Execute module code (Python, bash, etc.)
   ├─ Capture stdout/stderr
   ├─ Collect module return data
   └─ Apply filters if specified

6. Result Processing
   ├─ Parse JSON return from module
   ├─ Evaluate changed/failed conditions
   ├─ Check user-defined handlers
   ├─ Execute registered variable assignment
   └─ Trigger notifications (handlers)

7. Result Aggregation
   ├─ Combine with task metadata (name, tags, etc.)
   ├─ Store in runtime statistics
   └─ Return to playbook for conditionals/loops
```

**Module Return Data Structure**:

```json
{
  "changed": true,                    // Did module change state?
  "failed": false,                    // Did module error?
  "msg": "Operation completed",       // Human message
  
  // Module-specific return values
  "result": {
    "resource_id": "i-12345678",
    "status": "running"
  },
  
  // Debugging info
  "invocation": {
    "module_args": {...}              // Arguments passed to module
  },
  
  // For testing/debugging  
  "warnings": [],
  "deprecations": []
}
```

**Built-in vs. Local vs. Collection Modules**:

```
Module Types:

1. Built-in Modules (ansible.builtin namespace)
   - Packaged with Ansible core
   - Stable API; maintained by Ansible team
   - Examples: copy, template, debug, command, shell, file, user
   - Located: $INSTALLATION_PATH/ansible/modules/

2. Collection Modules (organization.collection namespace)
   - Packaged within collections
   - Versioned with collection
   - Examples: community.aws.ec2, kubernetes.core.k8s
   - Located: ~/.ansible/collections/ansible_collections/

3. Local Library Modules (library/ path)
   - Organization-specific custom modules
   - Located in playbook directory: ./library/
   - Backward compatibility; bypassing collections
   - Located: ./library/

Module Resolution Order:
$ ansible localhost -m my_module
1. Check ./library/my_module.py (local)
2. Check FQCN (if specified: org.collection.my_module)
3. Check ansible.builtin.my_module
4. Check community.general if community.general installed
5. Fail with "module not found"
```

#### Architecture Role

Modules are Ansible's execution primitives—everything Ansible does operationally flows through modules:

**Module Categories and Their Role**:

```
System Modules (user, group, service, systemd)
  ├─ Purpose: Systems administration primitives
  └─ Architecture: Lowest level—direct system interaction

Cloud Provider Modules (ec2, rds, iam, azure_vm)
  ├─ Purpose: Infrastructure provisioning
  └─ Architecture: Cloud API integration layer

Application Modules (mysql_user, postgresql_db, docker_container)
  ├─ Purpose: Application/service configuration
  └─ Architecture: Specialized tool integration

Network Modules (iptables, ufw, firewalld, ios_config)
  ├─ Purpose: Network infrastructure management
  └─ Architecture: Network device automation

File Modules (copy, template, sync, archive)
  ├─ Purpose: File and directory management
  └─ Architecture: Content deployment layer

Orchestration Modules (kubernetes.core.k8s, community.aws.ec2_instance)
  ├─ Purpose: Complex infrastructure operations
  └─ Architecture: Higher-order orchestration

Custom Modules (organization-specific)
  ├─ Purpose: Fill gaps in built-in/collection modules
  └─ Architecture: Extend Ansible capability
```

#### Production Usage Patterns

**Pattern 1: Conditional Module Invocation Based on Host Capabilities**

```yaml
---
- name: Configure package management
  hosts: all
  gather_facts: yes
  
  tasks:
    # Determine package manager from facts
    - name: Install packages on Red Hat family
      ansible.builtin.yum:
        name: "{{ packages }}"
        state: present
      when: ansible_os_family == "RedHat"
      
    - name: Install packages on Debian family
      ansible.builtin.apt:
        name: "{{ packages }}"
        state: present
      when: ansible_os_family == "Debian"
      
    - name: Install packages on Alpine
      ansible.builtin.apk:
        name: "{{ packages }}"
        state: present
      when: ansible_os_family == "Alpine"
```

**Pattern 2: Multi-Step Module Orchestration with State Validation**

```yaml
---
- name: Deploy database with validation
  hosts: db_servers
  
  tasks:
    - name: Create database user
      community.postgresql.postgresql_user:
        name: "{{ db_user }}"
        password: "{{ db_password }}"
        encrypted: yes
        state: present
      vars:
        ansible_user_id: postgres
      register: user_create
      
    - name: Create database
      community.postgresql.postgresql_db:
        name: "{{ db_name }}"
        owner: "{{ db_user }}"
        encoding: UTF-8
        state: present
      register: db_create
      
    - name: Verify database creation
      community.postgresql.postgresql_query:
        db: "{{ db_name }}"
        query: "SELECT 1"
      register: db_verify
      failed_when: "'1' not in db_verify.query_result[0]"
      
    - name: Set database status fact
      set_fact:
        database_deployed:
          name: "{{ db_name }}"
          owner: "{{ db_user }}"
          created: "{{ db_create.changed }}"
          verified: "{{ db_verify.query_result | length > 0 }}"
```

**Pattern 3: Async Module Execution for Long-Running Operations**

```yaml
---
- name: Backup and upgrade
  hosts: web_servers
  
  pre_tasks:
    - name: Start long-running backup (async)
      ansible.builtin.shell: /usr/local/bin/backup.sh
      async: 3600                       # Timeout after 1 hour
      poll: 0                           # Don't wait for result
      register: backup_job
      
  roles:
    - role: application_upgrade
    
  post_tasks:
    - name: Check backup job status
      async_status:
        jid: "{{ backup_job.ansible_job_id }}"
      until: backup_status.finished
      retries: 60
      delay: 10
      register: backup_status
```

#### DevOps Best Practices

**Practice 1: Use State Modules Over Command Modules**

❌ **Avoid**: Using shell/command modules for state management
```yaml
- name: Install package
  shell: "apt-get install -y nginx"      # Procedural; not idempotent
```

✅ **Preferred**: State-driven modules
```yaml
- name: Install nginx
  ansible.builtin.apt:
    name: nginx
    state: present                      # Idempotent; handles already-installed
```

**Practice 2: Register Results and Validate Outcomes**

```yaml
- name: Create resource and validate
  community.aws.ec2_instance:
    image_id: "{{ ami_id }}"
    instance_type: t3.medium
    state: present
  register: instance_creation
  
- name: Verify instance is running
  ansible.builtin.assert:
    that:
      - instance_creation.instances[0].state.name == "running"
      - instance_creation.instances[0].public_ip_address is defined
    fail_msg: "Instance creation failed or not in running state"
```

**Practice 3: Custom Modules for Complex Logic**

Develop custom modules for operations that don't fit neatly into existing module paradigms.

#### Common Pitfalls

**Pitfall 1: Not Checking Module Documentation**

❌ **Problematic**: Assuming module behavior
```yaml
- name: Copy file
  ansible.builtin.copy:
    src: app.jar
    dest: /opt/app/
    # Assumes 'dest' directory exists—fails if not
```

✅ **Solution**: Consult documentation; prepare state
```yaml
- name: Ensure destination directory exists
  ansible.builtin.file:
    path: /opt/app
    state: directory
    owner: app_user
    group: app_group
    mode: "0755"
    
- name: Copy file
  ansible.builtin.copy:
    src: app.jar
    dest: /opt/app/
```

**Pitfall 2: Ignoring Module Return Values**

❌ **Problematic**: Not validating module success
```yaml
- name: Download configuration
  ansible.builtin.get_url:
    url: "https://config.example.com/app.conf"
    dest: /etc/app.conf
  # If download fails, task still marks as changed
```

✅ **Solution**: Validate return values
```yaml
- name: Download configuration
  ansible.builtin.get_url:
    url: "https://config.example.com/app.conf"
    dest: /etc/app.conf
    checksum: "sha256:abc123..."
  register: config_download
  failed_when: 
    - config_download.failed or config_download.status_code != 200
```

### Practical Code Examples

**Example 1: Custom Module for Cloud Resource Validation**

```python
# library/validate_cloud_resources.py
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from ansible.module_utils.basic import AnsibleModule
import boto3
from botocore.exceptions import ClientError

def main():
    module = AnsibleModule(
        argument_spec=dict(
            resource_type=dict(
                type='str',
                required=True,
                choices=['ec2', 'rds', 's3', 'iam']
            ),
            resource_ids=dict(
                type='list',
                required=True
            ),
            region=dict(
                type='str',
                default='us-east-1'
            ),
            validation_criteria=dict(
                type='dict',
                default={}
            )
        ),
        supports_check_mode=True
    )
    
    resource_type = module.params['resource_type']
    resource_ids = module.params['resource_ids']
    region = module.params['region']
    criteria = module.params['validation_criteria']
    
    results = {
        'validated': [],
        'failed': [],
        'warnings': []
    }
    
    try:
        if resource_type == 'ec2':
            client = boto3.client('ec2', region_name=region)
            response = client.describe_instances(InstanceIds=resource_ids)
            
            for reservation in response['Reservations']:
                for instance in reservation['Instances']:
                    instance_id = instance['InstanceId']
                    
                    # Validate state
                    state = instance['State']['Name']
                    if state not in criteria.get('allowed_states', ['running']):
                        results['failed'].append({
                            'id': instance_id,
                            'reason': f"Instance in state '{state}', expected one of {criteria['allowed_states']}"
                        })
                    else:
                        results['validated'].append(instance_id)
                    
                    # Validate tags
                    tags = {tag['Key']: tag['Value'] for tag in instance.get('Tags', [])}
                    required_tags = criteria.get('required_tags', {})
                    for tag_key, tag_value in required_tags.items():
                        if tag_key not in tags:
                            results['warnings'].append(f"Instance {instance_id} missing tag '{tag_key}'")
        
        elif resource_type == 'rds':
            client = boto3.client('rds', region_name=region)
            response = client.describe_db_instances(DBInstanceIdentifier=resource_ids[0])
            
            for db in response['DBInstances']:
                db_id = db['DBInstanceIdentifier']
                status = db['DBInstanceStatus']
                
                if status != criteria.get('expected_status', 'available'):
                    results['failed'].append({
                        'id': db_id,
                        'reason': f"DB status '{status}', expected '{criteria['expected_status']}'"
                    })
                else:
                    results['validated'].append(db_id)
        
        # Determine overall success
        failed_count = len(results['failed'])
        changed = False  # Validation module doesn't change state
        
        if failed_count > 0:
            module.fail_json(
                msg=f"Validation failed for {failed_count} resources",
                validation_results=results
            )
        else:
            module.exit_json(
                changed=changed,
                msg=f"Successfully validated {len(results['validated'])} resources",
                validation_results=results
            )
    
    except ClientError as e:
        module.fail_json(msg=f"AWS API error: {str(e)}")
    except Exception as e:
        module.fail_json(msg=f"Validation error: {str(e)}")

if __name__ == '__main__':
    main()

# Usage in playbook:
---
- name: Validate EC2 instances
  validate_cloud_resources:
    resource_type: ec2
    resource_ids: "{{ ec2_instance_ids }}"
    region: us-east-1
    validation_criteria:
      allowed_states: [running, stopped]
      required_tags:
        Environment: production
        Owner: ops-team
  register: validation_result
```

**Example 2: Complex Multi-Module Orchestration**

```yaml
---
- name: Deploy and configure Kubernetes cluster
  hosts: k8s_masters
  gather_facts: yes
  
  pre_tasks:
    - name: Validate prerequisites
      block:
        - name: Check minimum Kubernetes version
          ansible.builtin.shell: kubectl version --short | grep -o 'v[0-9]\+\.[0-9]\+'
          register: k8s_version
          changed_when: false
          
        - name: Assert Kubernetes version >= 1.24
          ansible.builtin.assert:
            that:
              - k8s_version.stdout is version('v1.24', '>=')
            fail_msg: "Kubernetes version must be >= 1.24"
  
  tasks:
    - name: Create namespaces
      kubernetes.core.k8s:
        name: "{{ item }}"
        api_version: v1
        kind: Namespace
        state: present
      loop:
        - monitoring
        - logging
        - ingress
      register: namespace_creation
      
    - name: Add Helm repositories
      kubernetes.core.helm_repository:
        name: "{{ item.name }}"
        repo_url: "{{ item.url }}"
        state: present
      loop:
        - { name: prometheus, url: 'https://prometheus-community.github.io/helm-charts' }
        - { name: grafana, url: 'https://grafana.github.io/helm-charts' }
        - { name: ingress-nginx, url: 'https://kubernetes.github.io/ingress-nginx' }
      register: helm_repos
      
    - name: Deploy monitoring stack
      kubernetes.core.helm:
        name: prometheus
        chart_ref: prometheus/kube-prometheus-stack
        release_namespace: monitoring
        values:
          prometheus:
            prometheusSpec:
              retention: 30d
              storageSpec:
                accessModes: ["ReadWriteOnce"]
                resources:
                  requests:
                    storage: 50Gi
      register: prometheus_deploy
      
    - name: Deploy Grafana
      kubernetes.core.helm:
        name: grafana
        chart_ref: grafana/grafana
        release_namespace: monitoring
        values:
          adminPassword: "{{ grafana_admin_password }}"
          datasources:
            datasources.yaml:
              apiVersion: 1
              datasources:
              - name: Prometheus
                type: prometheus
                url: http://prometheus-operated:9090
      register: grafana_deploy
      
    - name: Deploy ingress controller
      kubernetes.core.helm:
        name: ingress
        chart_ref: ingress-nginx/ingress-nginx
        release_namespace: ingress
        values:
          controller:
            replicas: 3
            service:
              type: LoadBalancer
      register: ingress_deploy
      
    - name: Wait for all deployments
      kubernetes.core.k8s_info:
        kind: Deployment
        namespace: "{{ item }}"
        wait: yes
        wait_condition:
          type: Available
          status: "True"
        wait_sleep: 5
        wait_timeout: 300
      loop:
        - monitoring
        - ingress
        
    - name: Collect cluster information
      block:
        - name: Get ingress endpoint
          kubernetes.core.k8s_info:
            kind: Service
            namespace: ingress
            name: ingress-ingress-nginx-controller
          register: ingress_service
          
        - name: Set cluster facts
          set_fact:
            cluster_deployed:
              namespaces: "{{ namespace_creation.results | map(attribute='result.metadata.name') | list }}"
              helm_releases:
                - name: prometheus
                  status: "{{ prometheus_deploy.status.release }}"
                - name: grafana
                  status: "{{ grafana_deploy.status.release }}"
              ingress_endpoint: "{{ ingress_service.resources[0].status.loadBalancer.ingress[0].hostname }}"
              
    - name: Display cluster information
      ansible.builtin.debug:
        msg: |
          Kubernetes Cluster Deployed Successfully
          =============================================
          Namespaces: {{ cluster_deployed.namespaces | join(', ') }}
          Ingress Endpoint: {{ cluster_deployed.ingress_endpoint }}
          
          Access Grafana at: https://{{ cluster_deployed.ingress_endpoint }}/grafana
          Default admin password: (set in vault)
```

---

## Ansible Execution Strategies

### Textual Deep Dive

#### Internal Working Mechanism

**Execution Strategy Architecture**:

Ansible's execution strategy determines how tasks are distributed across hosts. The strategy plugin controls parallelization, blocking, and task ordering:

```
Strategy Plugin Responsibilities:

1. Host Iteration
   ├─ Determine which hosts to operate on
   ├─ Apply serial batching
   ├─ Track host completion status
   └─ Handle host failures

2. Task Queue Management
   ├─ Queue tasks for execution
   ├─ Track task dependencies
   ├─ Handle conditional task execution
   └─ Manage task result aggregation

3. Result Processing
   ├─ Collect module results
   ├─ Evaluate changed/failed conditions
   ├─ Trigger handlers
   └─ Update statistics

4. Synchronization
   ├─ Determine blocking points (when tasks wait)
   ├─ Manage async task polling
   ├─ Coordinate serial batches
   └─ Handle inter-host dependencies
```

**Built-in Strategy Plugins**:

```
linear (default)
├─ Tasks execute sequentially on all hosts
├─ Task completes on ALL hosts before next task
├─ Hosts executing in parallel, but synchronized at task boundary
└─ Suitable for: General infrastructure automation

free
├─ Host completes tasks independently
├─ No synchronization between hosts
├─ Faster when operations vary by host
└─ Suitable for: Heterogeneous clusters, independent operations

host_pinned
├─ All tasks for a host execute before moving to next host
├─ Useful when tasks have host affinity requirements
├─ Single host operates sequentially
└─ Suitable for: Stateful services, host-specific migrations

serial (combined with linear/free)
├─ Process N hosts, then next N hosts
├─ Enables rolling updates
├─ Deterministic batching
└─ Suitable for: Production deployments, rolling updates
```

**Execution Timeline Comparison**:

```
Scenario: 4 tasks, 3 hosts

Linear Strategy (default):
┌─────────────────────────────────────────┐
│ linear: tasks synchronized at boundary  │
├─────────────────────────────────────────┤
│ Task 1 │  Host1  Host2  Host3 │        
│        │  ▓▓▓▓   ▓▓▓▓   ▓▓▓▓  │ (parallel)
├────────┼──────────────────────┤
│ Task 2 │  Host1  Host2  Host3 │
│        │  ▓▓▓▓   ▓▓▓▓   ▓▓▓▓  │ (waits for all)
├────────┼──────────────────────┤
│ Task 3 │  Host1  Host2  Host3 │
│        │  ▓▓▓▓   ▓▓▓▓   ▓▓▓▓  │
└─────────────────────────────────────────┘
Total time: ▓▓▓▓ + ▓▓▓▓ + ▓▓▓▓ (longest host per task)

Free Strategy:
┌─────────────────────────────────────────┐
│ free: hosts independent                  │
├─────────────────────────────────────────┤
│ Host1 │  Task1 Task2 Task3 Task4   │
│       │  ▓▓▓▓ ▓▓▓   ▓▓▓▓  ▓▓      │
├───────┼──────────────────────────────┤
│ Host2 │  Task1        Task2    Task3   │
│       │  ▓▓   ════   ▓▓▓▓    ▓▓   │
├───────┼──────────────────────────────┤
│ Host3 │  Task1  Task2  Task3  Task4 │
│       │  ▓▓▓▓   ▓▓▓    ▓▓     ▓   │
└─────────────────────────────────────────┘
Total time: ▓ (fastest host completes all tasks)

Serial (rolling): 2 hosts at a time
┌─────────────────────────────────────────┐
│ serial: 2 batches                       │
├─────────────────────────────────────────┤
│ Batch 1  │  Host1  Host2  │
│ Task 1-4 │  ▓▓▓▓   ▓▓▓▓   │
├──────────┼─────────────────┤
│ Batch 2  │  Host3        │
│ Task 1-4 │  ▓▓▓▓        │
└─────────────────────────────────────────┘
Total time: ▓▓▓▓ + ▓▓▓▓ (2 batches)
```

**Async & Polling Mechanism**:

```
Async Task Execution:

1. Submit Task to Host
   └─ Return immediately with job ID

2. Client Polls Job Status
   ├─ sleep delay (default 1 second)
   ├─ poll job_status
   ├─ Repeat until finished
   └─ Timeout after async duration

Configuration:
- async: 600          # Timeout (seconds)
- poll: 0             # Don't wait (fire & forget)
- poll: 30            # Check every 30 seconds

Use Cases:
├─ Long-running operations (backups, builds)
├─ Parallel execution of independent tasks
└─ External system state checks
```

#### Architecture Role

Execution strategies are the orchestration layer that determine how aggressively Ansible parallelizes and synchronizes infrastructure operations:

**Strategic Positioning**:

```
┌─────────────────────────────────────────┐
│  Playbook                               │
│  (declares what to do)                  │
├─────────────────────────────────────────┤
│  Execution Strategy                     │
│  (determines HOW to parallelize)        │
├─────────────────────────────────────────┤
│  Inventory + Hosts                      │
│  (WHICH systems to operate on)          │
├─────────────────────────────────────────┤
│  Modules                                │
│  (WHAT operations to execute)           │
└─────────────────────────────────────────┘

Strategy determines:
- Parallelism (# concurrent hosts)
- Synchronization (coordination points)
- Failure behavior (continue vs. stop)
- Resource utilization (network, CPU)
```

#### Production Usage Patterns

**Pattern 1: Rolling Deployment with Health Checks**

```yaml
---
- name: Rolling application deployment
  hosts: app_servers
  serial: "{{ serial_batch_size | default(2) }}"
  
  pre_tasks:
    - name: Drain connections from load balancer
      debug:
        msg: "Removing {{ inventory_hostname }} from load balancer"
      # In production: call LB API to drain
      
  roles:
    - role: application_deploy
      vars:
        app_version: "{{ target_version }}"
        
  post_tasks:
    - name: Health check application
      uri:
        url: "http://{{ inventory_hostname }}:8080/healthz"
        method: GET
        status_code: 200
      register: health_check
      until: health_check.status == 200
      retries: 10
      delay: 5
      
    - name: Re-add to load balancer
      debug:
        msg: "Adding {{ inventory_hostname }} back to load balancer"
        
    - name: Pause between batches
      pause:
        seconds: 30
      when: inventory_hostname != ansible_play_hosts[-1]
      # Don't pause after last batch
```

**Pattern 2: Parallel Independent Operations with Free Strategy**

```yaml
---
- name: Parallel infrastructure provisioning
  hosts: localhost
  strategy: free
  gather_facts: no
  
  tasks:
    - name: Provision EC2 instances
      amazon.aws.ec2_instance:
        image_id: "{{ ami_id }}"
        instance_type: t3.medium
        count: 5
      async: 600
      poll: 0
      register: ec2_provision
      
    - name: Create RDS database
      amazon.aws.rds:
        db_instance_identifier: "{{ db_name }}"
        engine: postgres
        allocated_storage: 100
      async: 600
      poll: 0
      register: rds_provision
      
    - name: Create load balancer
      community.aws.elb:
        name: "{{ lb_name }}"
        zones: ["us-east-1a", "us-east-1b"]
      async: 600
      poll: 0
      register: elb_provision
      
  post_tasks:
    - name: Wait for EC2 provisioning
      async_status:
        jid: "{{ ec2_provision.ansible_job_id }}"
      until: ec2_result.finished
      retries: 120
      register: ec2_result
      
    - name: Wait for RDS provisioning
      async_status:
        jid: "{{ rds_provision.ansible_job_id }}"
      until: rds_result.finished
      retries: 120
      register: rds_result
      
    - name: Wait for LB provisioning
      async_status:
        jid: "{{ elb_provision.ansible_job_id }}"
      until: elb_result.finished
      retries: 120
      register: elb_result
```

**Pattern 3: Host-Pinned Strategy for Stateful Services**

```yaml
---
- name: Upgrade Kubernetes master nodes
  hosts: k8s_masters
  strategy: host_pinned          # Ensure all tasks for one host complete before next
  
  pre_tasks:
    - name: Cordon node from cluster
      community.kubernetes.kubernetes:
        api_key: "{{ k8s_api_key }}"
        # Prevent new pods from scheduling on this node
        
  roles:
    - role: kubernetes_upgrade
      vars:
        target_version: "{{ k8s_version }}"
        
  post_tasks:
    - name: Wait for node readiness
      community.kubernetes.kubernetes_info:
        kind: Node
        name: "{{ inventory_hostname }}"
        wait: yes
        wait_condition:
          type: Ready
          status: "True"
          
    - name: Uncordon node
      community.kubernetes.kubernetes:
        api_key: "{{ k8s_api_key }}"
        # Allow pods to be scheduled again
```

#### DevOps Best Practices

**Practice 1: Choose Strategy Based on Operation Type**

```yaml
# For web service deployment (homogeneous, synchronized)
- name: Deploy web services
  hosts: webservers
  strategy: linear              # Synchronized deployment
  serial: 2                      # Rolling: 2 at a time
  
# For cloud infrastructure provisioning (independent)
- name: Provision infrastructure
  hosts: localhost
  strategy: free                # Independent operations
  gather_facts: no

# For Kubernetes cluster upgrades (stateful, ordered)
- name: Upgrade Kubernetes
  hosts: k8s_nodes
  strategy: host_pinned         # All node tasks complete before next node
  serial: 1                      # One node at a time

# For batch operations (no inter-dependency)
- name: Collect diagnostics
  hosts: all
  strategy: free                # Maximum parallelism
```

**Practice 2: Implement Health Checks in Rolling Deployments**

```yaml
---
- name: Safe rolling deployment
  hosts: app_servers
  serial: "{{ batch_size | default(2) }}"
  
  roles:
    - application_deploy
    
  post_tasks:
    - name: Health check
      uri:
        url: "http://{{ inventory_hostname }}:{{ app_port }}/health"
        status_code: 200
      retries: 10
      delay: 5
      register: health
      failed_when: health.failed
      
    - name: Validate metrics  
      ansible.builtin.assert:
        that:
          - error_rate | float < 0.01       # < 1% error rate
          - response_time | float < 500     # < 500ms response time
        fail_msg: "Health metrics out of range"
        
    - name: Abort deployment on health failure
      ansible.builtin.fail:
        msg: "Health check failed; stopping deployment"
      when: health.failed or not assert_passed
```

**Practice 3: Monitor Execution Metrics**

```yaml
- name: Track deployment metrics
  hosts: all
  
  tasks:
    - name: Execute deployment task
      include_role:
        name: deploy_app
      register: deploy_result
      
    - name: Record metrics
      set_fact:
        deployment_metrics:
          host: "{{ inventory_hostname }}"
          duration: "{{ deploy_result.duration | default(0) }}"
          changed: "{{ deploy_result.changed }}"
          failed: "{{ deploy_result.failed }}"
          timestamp: "{{ now(utc=True) }}"
          
    - name: Send metrics to monitoring
      shell: |
        curl -X POST http://metrics.internal/api/v1/metrics \
          -H "Content-Type: application/json" \
          -d '{{ deployment_metrics | to_json }}'
```

#### Common Pitfalls

**Pitfall 1: Incorrect Serial Value for Rolling Deployments**

❌ **Problematic**: Serial value exceeds operational safety
```yaml
- hosts: 100_production_servers
  serial: 50          # Deploys 50 at once—too much risk
  # If deployment fails, 50 hosts in bad state
```

✅ **Solution**: Conservative rolling deployment
```yaml
- hosts: 100_production_servers
  serial: 2           # Deploys 2 at a time
  # Risk limited to 2 hosts; rollback possible
  
  post_tasks:
    - name: Comprehensive health checks
      include_tasks: health_checks.yml
```

**Pitfall 2: Async Without Polling for Long Operations**

❌ **Problematic**: Fire-and-forget without validation
```yaml
- name: Long-running backup
  shell: /backup/full_backup.sh
  async: 7200
  poll: 0             # Doesn't wait; doesn't check result
  # Task completes "successfully" even if backup fails
```

✅ **Solution**: Async with result validation
```yaml
- name: Start backup
  shell: /backup/full_backup.sh
  async: 7200
  poll: 0
  register: backup_job
  
- name: Monitor backup completion
  async_status:
    jid: "{{ backup_job.ansible_job_id }}"
  register: backup_result
  until: backup_result.finished
  retries: 300
  delay: 10
  
- name: Validate backup success
  assert:
    that:
      - backup_result.rc == 0
      - backup_result.stdout | regex_search('backup completed')
```

**Pitfall 3: Free Strategy with Host Dependencies**

❌ **Problematic**: Using free strategy when tasks have inter-host dependencies
```yaml
- hosts: all
  strategy: free
  
  tasks:
    - name: Configure database primary
      include: primary_setup.yml
      when: inventory_hostname == db_primary
      
    - name: Configure database replica (depends on primary)
      include: replica_setup.yml
      when: inventory_hostname == db_replica
      # Might run before primary setup completes!
```

✅ **Solution**: Use linear strategy or explicit dependencies
```yaml
- hosts: all
  strategy: linear    # Synchronize at task boundary
  
  roles:
    - role: db_primary
      when: inventory_hostname == db_primary
      
    - role: db_replica
      when: inventory_hostname == db_replica
      # Task executes on all hosts; waits for completion
```

**Pitfall 4: Ignoring Inventory Order**

❌ **Problematic**: Assuming hosts execute in specific order
```yaml
- hosts: k8s_nodes
  serial: 1
  
  tasks:
    - name: Upgrade node (assumes ordered)
      include: upgrade.yml
    # Assumes first host is control plane, but inventory order undefined
```

✅ **Solution**: Explicit host specification
```yaml
- name: Upgrade control plane first
  hosts: k8s_masters
  serial: 1
  roles:
    - k8s_upgrade

- name: Upgrade worker nodes
  hosts: k8s_workers
  serial: 2
  roles:
    - k8s_upgrade
```

### Practical Code Examples

**Example 1: Advanced Rolling Deployment**

```yaml
---
- name: Production application rolling deployment
  hosts: app_servers
  gather_facts: yes
  
  vars:
    health_check_max_attempts: 10
    health_check_delay: 5
    error_rate_threshold: 0.01
    response_time_threshold: 500  # milliseconds
    
  pre_tasks:
    - name: Log deployment start
      debug:
        msg: "Starting deployment of {{ app_name }} v{{ target_version }} on {{ inventory_hostname }}"
        
    - name: Collect current metrics
      set_fact:
        pre_deployment_metrics:
          host: "{{ inventory_hostname }}"
          timestamp: "{{ now(utc=True).isoformat() }}"

  roles:
    - role: app_deployment
      vars:
        app_version: "{{ target_version }}"
        deployment_strategy: rolling
        
  post_tasks:
    - name: Verify application startup
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:{{ app_port }}/status"
        method: GET
        status_code: 200
      register: startup_check
      retries: "{{ health_check_max_attempts }}"
      delay: "{{ health_check_delay }}"
      until: startup_check.status == 200
      failed_when: startup_check.failed
      
    - name: Query application metrics
      uri:
        url: "http://{{ ansible_default_ipv4.address }}:{{ app_port }}/metrics"
        method: GET
        return_content: yes
      register: app_metrics
      until: app_metrics.status == 200
      retries: 5
      
    - name: Validate application health
      block:
        - name: Parse metrics
          set_fact:
            current_error_rate: "{{ app_metrics.content | from_json | json_query('system.error_rate') }}"
            current_response_time: "{{ app_metrics.content | from_json | json_query('system.avg_response_time') }}"
            
        - name: Assert application health
          assert:
            that:
              - current_error_rate | float < error_rate_threshold
              - current_response_time | float < response_time_threshold
            fail_msg: |
              Application health check failed
              Error rate: {{ current_error_rate }} (threshold: {{ error_rate_threshold }})
              Response time: {{ current_response_time }}ms (threshold: {{ response_time_threshold }}ms)
              
      rescue:
        - name: Rollback deployment on health failure
          debug:
            msg: "Health check failed; initiating rollback"
            
        - name: Rollback to previous version
          include_role:
            name: app_deployment
          vars:
            app_version: "{{ previous_version }}"
            deployment_action: rollback
            
        - name: Fail play after rollback
          fail:
            msg: "Deployment rolled back due to health check failure"
            
    - name: Pause between batches
      pause:
        seconds: 30
        prompt: "Press enter to continue to next host or Ctrl+C to abort"
      when: inventory_hostname != ansible_play_hosts[-1]
      # Final host continues without pause
      
    - name: Log deployment completion
      debug:
        msg: "Successfully deployed {{ app_name }} v{{ target_version }} on {{ inventory_hostname }}"

- name: Deployment summary
  hosts: localhost
  gather_facts: no
  run_once: true
  
  tasks:
    - name: Display deployment statistics
      debug:
        msg: |
          Deployment Complete
          ===================
          Application: {{ app_name }}
          Version: {{ target_version }}
          Hosts deployed: {{ play_hosts | length }}
          Status: Success
```

**Example 2: Parallel Infrastructure Provisioning with Wait**

```yaml
---
- name: Multi-component infrastructure provisioning
  hosts: localhost
  gather_facts: no
  
  tasks:
    - name: Provision EC2 instances (async)
      amazon.aws.ec2_instance:
        image_id: "{{ ami_id }}"
        instance_type: "{{ instance_type }}"
        count: "{{ instance_count }}"
        network:
          assign_public_ip: yes
        state: present
      async: 600
      poll: 0
      register: ec2_job
      
    - name: Provision RDS database (async)
      community.aws.rds:
        db_instance_identifier: "{{ db_instance_id }}"
        db_instance_class: "{{ db_instance_class }}"
        engine: postgres
        master_username: "{{ db_admin_username }}"
        master_userpassword: "{{ db_admin_password }}"
        allocated_storage: "{{ db_allocated_storage }}"
        state: present
      async: 1800
      poll: 0
      register: rds_job
      
    - name: Provision load balancer (async)
      community.aws.elb:
        name: "{{ lb_name }}"
        state: present
        zones: "{{ aws_availability_zones }}"
        listeners:
          - protocol: HTTP
            load_balancer_port: 80
            instance_port: 80
          - protocol: HTTPS
            load_balancer_port: 443
            instance_port: 8443
      async: 300
      poll: 0
      register: elb_job
      
    - name: Monitor EC2 provisioning
      async_status:
        jid: "{{ ec2_job.ansible_job_id }}"
      register: ec2_result
      until: ec2_result.finished
      retries: 120
      delay: 5
      
    - name: Monitor RDS provisioning
      async_status:
        jid: "{{ rds_job.ansible_job_id }}"
      register: rds_result
      until: rds_result.finished
      retries: 360
      delay: 10
      
    - name: Monitor load balancer provisioning
      async_status:
        jid: "{{ elb_job.ansible_job_id }}"
      register: elb_result
      until: elb_result.finished
      retries: 60
      delay: 5
      
    - name: Register instances with load balancer
      community.aws.elb_instance:
        instance_id: "{{ item }}"
        elb_name: "{{ lb_name }}"
        state: present
      loop: "{{ ec2_result.instance_ids }}"
      
    - name: Output provisioning summary
      debug:
        msg: |
          Infrastructure Provisioning Complete
          =====================================
          EC2 Instances:
            - IDs: {{ ec2_result.instance_ids}}
            - Public IPs: {{ ec2_result.public_ips }}
          RDS Database:
            - Endpoint: {{ rds_result.endpoint.address }}
            - Port: {{ rds_result.endpoint.port }}
          Load Balancer:
            - DNS Name: {{ elb_result.dns_name }}
            - Status: {{ elb_result.status }}
```

---

## Hands-on Scenarios

### Scenario 1: Emergency Rollback During Production Deployment Failure

**Problem Statement**

A SaaS company running a critical payment processing microservice experienced a failed deployment. The new version (3.2.0) introduced a bug in the payment validation logic, causing transactions to fail with silent errors. The bug went undetected through staging because the test dataset didn't include edge cases present in production.

After 45 seconds of observing errors in production metrics, the on-call engineer needs to:
1. Stop the faulty deployment immediately
2. Identify which infrastructure components are affected
3. Roll back to the last known good version (3.1.5)
4. Verify system stability
5. Document what failed for post-mortem

**Architecture Context**

```
Production Setup:
- 50 payment-processing pods across 5 AZs
- Rolling deployment strategy (5 pods at a time)
- Kubernetes cluster with health checks
- Prometheus monitoring for error rate detection
- Ansible playbook for coordinated rollback

Current State:
- 35 pods running v3.2.0 (faulty)
- 15 pods still running v3.1.5 (stable)
- Error rate: 12% (alert threshold: 2%)
- Request latency: 800ms (normal: 150ms)
```

**Step-by-Step Implementation**

```yaml
# playbooks/emergency_rollback.yml
---
- name: Emergency Payment Service Rollback
  hosts: localhost
  gather_facts: no
  
  vars:
    failed_version: "3.2.0"
    rollback_version: "3.1.5"
    k8s_namespace: "production"
    service_name: "payment-processor"
    health_check_retries: 30
    health_check_delay: 5
    error_rate_threshold: 2.0
    
  pre_tasks:
    - name: Create incident snapshot
      block:
        - name: Capture current deployment state
          kubernetes.core.k8s_info:
            kind: Deployment
            namespace: "{{ k8s_namespace }}"
            name: "{{ service_name }}"
          register: current_deployment
          
        - name: Query error rate from Prometheus
          ansible.builtin.uri:
            url: "http://prometheus:9090/api/v1/query"
            method: POST
            body_format: form-urlencoded
            body:
              query: 'rate(payment_errors_total[5m])'
          register: error_rate_query
          
        - name: Log incident details
          ansible.builtin.copy:
            content: |
              INCIDENT SNAPSHOT - {{ now(utc=True).isoformat() }}
              ================================================
              
              Failed Version: {{ failed_version }}
              Current Pod Status:
              {{ current_deployment.resources[0].status | to_nice_yaml }}
              
              Error Rate: {{ error_rate_query.json.data.result[0].value[1] }}%
              
              Action: Initiating rollback to {{ rollback_version }}
            dest: "/var/log/incidents/rollback_{{ now(utc=True).strftime('%Y%m%d_%H%M%S') }}.log"
            
  roles:
    - role: k8s_emergency_rollback
      vars:
        target_version: "{{ rollback_version }}"
        deployment_name: "{{ service_name }}"
        
  post_tasks:
    - name: Verify rollback completion
      kubernetes.core.k8s_info:
        kind: Pod
        namespace: "{{ k8s_namespace }}"
        label_selectors:
          - "app={{ service_name }}"
      register: pod_status
      until: pod_status.resources | length > 0 and (pod_status.resources | map(attribute='status.phase') | list | unique == ['Running'])
      retries: "{{ health_check_retries }}"
      delay: "{{ health_check_delay }}"
      
    - name: Validate error rate return to normal
      block:
        - name: Query error rate again
          ansible.builtin.uri:
            url: "http://prometheus:9090/api/v1/query"
            method: POST
            body_format: form-urlencoded
            body:
              query: 'rate(payment_errors_total[5m])'
          register: post_rollback_error_rate
          until: (post_rollback_error_rate.json.data.result[0].value[1] | float) < error_rate_threshold
          retries: "{{ health_check_retries }}"
          delay: "{{ health_check_delay }}"
          
        - name: Verify latency normalized
          ansible.builtin.uri:
            url: "http://prometheus:9090/api/v1/query"
            method: POST
            body_format: form-urlencoded
            body:
              query: 'histogram_quantile(0.95, payment_request_duration_seconds_bucket)'
          register: latency_query
          until: (latency_query.json.data.result[0].value[1] | float) < 250
          retries: 10
          delay: 5
          
      rescue:
        - name: Escalate if metrics don't improve
          ansible.builtin.uri:
            url: "{{ incident_escalation_webhook }}"
            method: POST
            body_format: json
            body:
              severity: critical
              message: "Rollback completed but metrics not recovering. Manual intervention required."
          when: incident_escalation_webhook is defined
          
    - name: Notify stakeholders
      debug:
        msg: |
          🔄 ROLLBACK COMPLETED SUCCESSFULLY
          ===================================
          Environment: Production
          Service: {{ service_name }}
          Rolled back from v{{ failed_version }} to v{{ rollback_version }}
          
          Current Status:
          - Pods Running: {{ pod_status.resources | length }}
          - Error Rate: {{ post_rollback_error_rate.json.data.result[0].value[1] }}%
          - P95 Latency: {{ latency_query.json.data.result[0].value[1] }}ms
          
          Next Steps:
          1. Root cause analysis on failed version
          2. Additional testing in staging
          3. Decision on re-deployment timeline

# roles/k8s_emergency_rollback/tasks/main.yml
---
- name: Trigger immediate rollback
  kubernetes.core.k8s:
    state: present
    namespace: "{{ deployment_name_namespace }}"
    definition:
      apiVersion: apps/v1
      kind: Deployment
      metadata:
        name: "{{ deployment_name }}"
      spec:
        template:
          spec:
            containers:
            - name: "{{ deployment_name }}"
              image: "{{ container_registry }}/{{ deployment_name }}:{{ target_version }}"
              # This forces K8s to rolling update to new image

- name: Wait for rollback pods to be ready
  kubernetes.core.k8s_info:
    kind: Pod
    namespace: "{{ deployment_name_namespace }}"
    label_selectors:
      - "app={{ deployment_name }}"
  register: pods
  until: 
    - pods.resources | length > 0
    - (pods.resources | map(attribute='status.containerStatuses') | flatten | map(attribute='ready') | list | unique) == [True]
  retries: 30
  delay: 2
```

**Best Practices Applied**

1. **Incident Snapshot**: Captured state before rollback for forensics
2. **Automated Health Checks**: Didn't rely on manual verification—automated Prometheus queries
3. **Graceful Coordination**: Used Kubernetes rolling update mechanism rather than brute-force pod replacement
4. **Verification Loop**: Confirmed metrics returned to normal before declaring success
5. **Escalation Path**: If metrics didn't improve post-rollback, escalated to human team
6. **Documentation**: Logged details for post-mortem analysis

---

### Scenario 2: Debugging Multi-Environment Variable Precedence Issue

**Problem Statement**

A DevOps engineer deployed a new version of a microservice across three environments (dev, staging, production). The application worked perfectly in dev and staging but failed in production with a connection timeout error. Investigation revealed that the service couldn't connect to its database because the wrong connection string was being used—the database hostname was pointing to staging instead of production.

The root cause was unclear: the variable seemed defined correctly in production configuration files, but somehow the staging value was being used.

**Architecture Context**

```
Configuration Structure:
inventory/
├── group_vars/
│   ├── all/common.yml
│   ├── dev/
│   │   ├── main.yml
│   │   └── vault.yml
│   ├── staging/
│   │   ├── main.yml
│   │   └── vault.yml
│   └── production/
│       ├── main.yml
│       └── vault.yml
└── host_vars/

Variable Precedence (simplified):
1. Command line (-e flag)
2. Playbook vars:
3. Role vars/main.yml
4. Group vars
5. Host vars
6. Role defaults/main.yml
```

**Debugging Process**

```yaml
# Create diagnostic playbook
---
- name: Debug variable precedence issue
  hosts: production
  gather_facts: yes
  
  vars:
    debug_all_vars: yes
    
  tasks:
    - name: Display all database-related variables
      ansible.builtin.debug:
        msg: |
          DB Configuration Debug Report
          ==============================
          
          db_host: {{ db_host }}
          db_port: {{ db_port }}
          db_name: {{ db_name }}
          
          Source Investigation:
          - From role defaults: (check roles/app_service/defaults/main.yml)
          - From group_vars/all: (check group_vars/all/main.yml)
          - From group_vars/production: (check group_vars/production/main.yml)
          - From host_vars: (check host_vars/)
          
    - name: Export ALL variables for analysis
      set_fact:
        all_facts: "{{ hostvars[inventory_hostname] }}"
      register: all_vars_export
      
    - name: Filter database variables
      set_fact:
        db_vars: "{{ hostvars[inventory_hostname] | dict2items | selectattr('key', 'match', '^db_') | list }}"
        
    - name: Show precedence analysis
      debug:
        msg: |
          Variables matching 'db_*' pattern:
          {% for item in db_vars %}
          - {{ item.key }}: {{ item.value }}
          {% endfor %}

# Analysis output reveals:
# The issue: db_host has value 'staging-db.internal' instead of 'prod-db.internal'
# Why: group_vars/staging/main.yml was loaded AFTER group_vars/production/main.yml
# because inventory groups are processed alphabetically!

# Solution: Use explicit inventory hierarchy
---
# inventory/hosts file structure (WRONG - alphabetical hell)
[dev]
dev_server1

[production]
prod_server1

[staging]
staging_server1

# inventory/hosts file structure (CORRECT - explicit hierarchy)
[dev]
dev_server1

[staging]
staging_server1

[production]
prod_server1

# Better: Use nested groups with clear precedence
[aws]

[aws:children]
dev_aws
staging_aws
production_aws

[dev_aws]
dev_server1

[staging_aws]
staging_server1

[production_aws]
prod_server1

# group_vars/ structure (clarify precedence)
group_vars/
├── all/
│   └── common.yml              # Applied to ALL, lowest precedence
├── aws/
│   └── aws_common.yml          # Applied to aws group
├── dev_aws/
│   ├── main.yml                # Dev-specific
│   └── vault.yml
├── staging_aws/
│   ├── main.yml                # Staging-specific
│   └── vault.yml
└── production_aws/
    ├── main.yml                # Production-specific
    └── vault.yml               # Encrypted production secrets
```

**Best Practices Applied**

1. **Explicit Group Hierarchy**: Nested groups with clear naming prevent alphabetical ordering issues
2. **Environment-Specific Directories**: Segregate dev/staging/prod completely
3. **Variable Documentation**: Each group_vars file documents its precedence level
4. **Validation Playbook**: Created diagnostic playbook to inspect actual variable values
5. **Inventory Structure**: Used meaningful group names that reflect environment importance

**Root Cause**

The issue was a silent mistake: `group_vars/staging/main.yml` defined `db_host: staging-db.internal` with the same variable name. Ansible's precedence order within `group_vars/` depends on file system ordering (alphabetical), so `staging/` loaded after and overwrote `production/`.

---

### Scenario 3: Collection Dependency Version Conflict Resolution

**Problem Statement**

A company maintains an internal Ansible collection (`myorg.platform`) used across 50+ infrastructure automation playbooks. The collection version 2.0.0 was released with a breaking change: the internal role `vpc_provisioner` changed its input variable from `vpc_name` to `vpc_identifier`.

When the company tried to upgrade to collection version 2.0.0 in one deployment pipeline, it discovered:
1. Ten playbooks still using the old variable name (`vpc_name`)
2. The dependency mechanism couldn't catch this—no build-time validation
3. Forcing the upgrade breaks existing playbooks
4. Not upgrading means missing security fixes from downstream dependencies

**Architecture Context**

```
Dependency Chain:
myorg.platform 2.0.0
  ├─ community.aws 5.5.0 (NEW—has security fixes)
  ├─ kubernetes.core 2.4.0
  └─ (previous: community.aws 5.2.0, no security fixes)

Problem:
- Can't use 2.0.0 without breaking 10 playbooks
- Must upgrade for security
- Need coordinated migration strategy
```

**Step-by-Step Solution**

```yaml
# Step 1: Create Compatibility Layer (Collection v2.0.1)
# collections/myorg/platform/roles/vpc_provisioner/defaults/main.yml
---
# NEW variable name (preferred)
vpc_identifier: "{{ cluster_name }}-vpc"

# BACKWARD COMPATIBILITY: Support old variable name
vpc_name: "{{ vpc_identifier }}"     # Maps to new name

# roles/vpc_provisioner/tasks/main.yml includes:
---
- name: Handle backward compatibility
  block:
    - name: Check if old variable name used
      debug:
        msg: "WARNING: vpc_name is deprecated; use vpc_identifier"
      when: vpc_name is defined and vpc_identifier is not defined
      
    - name: Use vpc_name if vpc_identifier not provided
      set_fact:
        vpc_identifier: "{{ vpc_name }}"
      when: vpc_name is defined and vpc_identifier is not defined
      
- name: Validate vpc_identifier
  assert:
    that:
      - vpc_identifier is defined and vpc_identifier != ""
    fail_msg: "vpc_identifier must be defined"
    
# Step 2: Create Migration Path
# Create v2.0.1 (backward compatible) that logs deprecation
# Create v2.1.0 (removes old variable, requires migration)

# Step 3: Communicate and Coordinate Migration
# requirements.yml for gradual rollout:
collections:
  - name: myorg.platform
    version: "2.0.1"          # Backward compatible; has security fixes

# Step 4: Validation Playbook
---
- name: Audit playbooks for deprecated variables
  hosts: localhost
  gather_facts: no
  
  tasks:
    - name: Find all playbooks using vpc_name
      find:
        paths: playbooks/
        patterns: "*.yml"
        recurse: yes
      register: playbook_files
      
    - name: Check for deprecated variables
      block:
        - name: Scan playbook for deprecated variable usage
          shell: grep -l "vpc_name" {{ item.path }}
          register: grep_result
          failed_when: false
          loop: "{{ playbook_files.files }}"
          
        - name: Report deprecated usage
          debug:
            msg: "Playbook uses deprecated 'vpc_name': {{ item.item.path }}"
          loop: "{{ grep_result.results }}"
          when: item.rc == 0
          
        - name: Create migration report
          copy:
            content: |
              COLLECTION MIGRATION REPORT
              ============================
              
              Deprecated Variable Usage Found:
              {% for item in grep_result.results %}
              {% if item.rc == 0 %}
              - {{ item.item.path }}
              {% endif %}
              {% endfor %}
              
              Required Changes:
              1. Replace all occurrences of 'vpc_name' with 'vpc_identifier'
              2. Test in staging environment
              3. Deploy after validation
            dest: migration_report.txt
```

**Best Practices Applied**

1. **Semantic Versioning**: Clear communication that 2.0.0 breaks API  
2. **Backward Compatibility Layer**: Version 2.0.1 supports both old and new variable names
3. **Deprecation Warnings**: Logger messages guide users to new API
4. **Automated Audit**: Playbook finds all usages of deprecated variables
5. **Phased Migration**: Gives teams time to update their playbooks
6. **Security Balance**: Allows upstream security fixes while maintaining compatibility

---

### Scenario 4: Performance Optimization Through Execution Strategy Selection

**Problem Statement**

A company provisioning 200+ AWS EC2 instances nightly via Ansible experienced a 4-hour deployment window. The deployment creates VPCs, security groups, network ACLs, subnets, NAT gateways, route tables, and finally EC2 instances. The entire process seemed slow, but it wasn't clear where the bottleneck was.

Analysis showed that many provisioning operations were independent (creating VPC #1 and VPC #2 don't depend on each other), yet the default linear strategy executed them sequentially. This created unnecessary waiting time.

**Architecture Context**

```
Current Playbook (Linear Strategy):

Task: Create VPC #1
├─ Create for region us-east-1
├─ Create subnets
└─ Create route tables
                        (WAITS FOR ALL)
Task: Create VPC #2
├─ Create for region us-west-2
├─ Create subnets
└─ Create route tables
                        (WAITS FOR ALL)
Task: Create VPC #3
...
(repeats for 200 instances)

Timeline: 4 hours (sequential operations)
```

**Optimization Implementation**

```yaml
# Before: Linear strategy (slow)
---
- name: Provision infrastructure
  hosts: localhost
  gather_facts: no
  
  tasks:
    - name: Create VPC
      loop: "{{ regions }}"
      amazon.aws.ec2_vpc_net:
        name: "vpc-{{ item }}"
        cidr_block: "10.{{ idx }}.0.0/16"
    # Creates VPC #1, waits, creates VPC #2, waits, creates VPC #3...
    # Total: ~240 minutes

# After: Free strategy + async (optimized)
---
- name: Provision infrastructure
  hosts: localhost
  gather_facts: no
  strategy: free                    # Independent task execution
  vars:
    async_job_poll_interval: 30
    
  tasks:
    # Phase 1: Start all VPC creations asynchronously
    - name: Create VPCs (async)
      amazon.aws.ec2_vpc_net:
        name: "vpc-{{ item }}"
        cidr_block: "10.{{ idx }}.0.0/16"
      async: 600
      poll: 0                      # Don't wait
      loop: "{{ regions }}"
      loop_control:
        index_var: idx
      register: vpc_jobs
      
    # Phase 2: While VPCs create, start security group creations
    - name: Create security groups (async)
      amazon.aws.ec2_group:
        name: "sg-{{ item }}"
        vpc_id: vpc-temp
        description: "Security group {{ item }}"
      async: 600
      poll: 0
      loop: "{{ security_groups }}"
      register: sg_jobs
      
    # Phase 3: Monitor VPC creation completion
    - name: Monitor VPC creation
      async_status:
        jid: "{{ item.ansible_job_id }}"
      register: vpc_result
      until: vpc_result.finished
      retries: 60
      delay: 10
      loop: "{{ vpc_jobs.results }}"
      
    # Phase 4: Now proceed with subnet and route creation
    - name: Create subnets with VPC IDs
      amazon.aws.ec2_vpc_subnet:
        vpc_id: "{{ item.vpc_id }}"          # From completed VPC jobs
        cidr: "10.{{ idx }}.{{ subnet_idx }}.0/24"
      loop: "{{ vpc_result.results }}"
      
    # Phase 5: Parallel instance creation
    - name: Create EC2 instances (async)
      amazon.aws.ec2_instance:
        image_id: "{{ ami_id }}"
        instance_type: t3.medium
        subnet_id: "{{ item }}"
      async: 600
      poll: 0
      loop: "{{ subnet_ids }}"
      register: instance_jobs

# Performance Comparison
Timeline with Optimization:

Minute 0-10: Create all VPCs (parallel), SGs (parallel)
Minute 10-20: Create all subnets, route tables (parallel)
Minute 20-45: Create all 200 EC2 instances (in parallel batches)
              Free strategy processes as fast as AWS API allows

Total: ~45 minutes (was 240 minutes)
Speedup: 5.3x faster
```

**Best Practices Applied**

1. **Strategy Selection**: Free strategy for independent operations
2. **Async/Poll Pattern**: Non-blocking operations with monitoring
3. **Phase-Based Execution**: Logical grouping of related operations
4. **Dependency Ordering**: VPCs created before subnets, subnets before instances
5. **Monitoring**: Async_status polling to detect completion
6. **Error Handling**: If one instance fails, others continue (resilient)

---

### Scenario 5: Custom Module Development for Proprietary API

**Problem Statement**

A financial services company uses a proprietary hardware security module (HSM) for key management. Standard Ansible modules don't support their HSM's REST API. Deployments require manual API calls to:
1. Request key rotation
2. Verify key fingerprints  
3. Update key policies
4. Audit key access

This manual step created bottlenecks and inconsistencies in production deployments. The company decided to develop a custom Ansible module to automate HSM interactions.

**Implementation**

```python
# library/hsm_key_manager.py
#!/usr/bin/env python3
# -*- coding: utf-8 -*-

from ansible.module_utils.basic import AnsibleModule
import requests
import json
import hashlib
from typing import Dict, Any, List

class HSMKeyManager:
    def __init__(self, api_endpoint: str, api_key: str, module: AnsibleModule):
        self.api_endpoint = api_endpoint
        self.api_key = api_key
        self.module = module
        self.base_url = f"https://{api_endpoint}/api/v1"
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
        
    def rotate_key(self, key_id: str, new_algorithm: str) -> Dict[str, Any]:
        """Rotate HSM key to new algorithm"""
        url = f"{self.base_url}/keys/{key_id}/rotate"
        payload = {
            "algorithm": new_algorithm
        }
        
        response = requests.post(url, json=payload, headers=self.headers, timeout=30)
        
        if response.status_code != 200:
            self.module.fail_json(
                msg=f"Failed to rotate key {key_id}",
                status_code=response.status_code,
                response_text=response.text
            )
        
        return response.json()
        
    def verify_key_fingerprint(self, key_id: str, expected_fingerprint: str) -> bool:
        """Verify key fingerprint matches expected value"""
        url = f"{self.base_url}/keys/{key_id}/fingerprint"
        
        response = requests.get(url, headers=self.headers, timeout=30)
        
        if response.status_code != 200:
            self.module.fail_json(
                msg=f"Failed to get fingerprint for key {key_id}",
                status_code=response.status_code
            )
        
        actual_fingerprint = response.json()["fingerprint"]
        
        if actual_fingerprint != expected_fingerprint:
            return False
        return True
        
    def update_key_policy(self, key_id: str, policy: Dict[str, Any]) -> Dict[str, Any]:
        """Update key access policy"""
        url = f"{self.base_url}/keys/{key_id}/policy"
        
        response = requests.put(url, json=policy, headers=self.headers, timeout=30)
        
        if response.status_code != 200:
            self.module.fail_json(
                msg=f"Failed to update policy for key {key_id}",
                status_code=response.status_code,
                response_text=response.text
            )
        
        return response.json()
        
    def audit_key_access(self, key_id: str, days: int = 7) -> List[Dict[str, Any]]:
        """Get audit log for key access"""
        url = f"{self.base_url}/keys/{key_id}/audit"
        params = {"days": days}
        
        response = requests.get(url, headers=self.headers, params=params, timeout=30)
        
        if response.status_code != 200:
            self.module.fail_json(
                msg=f"Failed to retrieve audit log for key {key_id}",
                status_code=response.status_code
            )
        
        return response.json()["audit_entries"]

def main():
    module = AnsibleModule(
        argument_spec=dict(
            api_endpoint=dict(type='str', required=True),
            api_key=dict(type='str', required=True, no_log=True),
            action=dict(type='str', required=True, 
                       choices=['rotate', 'verify', 'update_policy', 'audit']),
            key_id=dict(type='str', required=True),
            new_algorithm=dict(type='str', required=False),
            expected_fingerprint=dict(type='str', required=False),
            policy=dict(type='dict', required=False),
            audit_days=dict(type='int', default=7)
        ),
        required_if=[
            ('action', 'rotate', ['new_algorithm']),
            ('action', 'verify', ['expected_fingerprint']),
            ('action', 'update_policy', ['policy'])
        ]
    )
    
    api_endpoint = module.params['api_endpoint']
    api_key = module.params['api_key']
    action = module.params['action']
    key_id = module.params['key_id']
    
    hsm = HSMKeyManager(api_endpoint, api_key, module)
    
    try:
        if action == 'rotate':
            new_algorithm = module.params['new_algorithm']
            result = hsm.rotate_key(key_id, new_algorithm)
            module.exit_json(
                changed=True,
                msg=f"Key {key_id} rotated successfully",
                result=result
            )
            
        elif action == 'verify':
            expected_fingerprint = module.params['expected_fingerprint']
            verified = hsm.verify_key_fingerprint(key_id, expected_fingerprint)
            module.exit_json(
                changed=False,
                verified=verified,
                msg="Fingerprint verification complete"
            )
            
        elif action == 'update_policy':
            policy = module.params['policy']
            result = hsm.update_key_policy(key_id, policy)
            module.exit_json(
                changed=True,
                msg=f"Policy for key {key_id} updated successfully",
                result=result
            )
            
        elif action == 'audit':
            audit_days = module.params['audit_days']
            audit_entries = hsm.audit_key_access(key_id, audit_days)
            module.exit_json(
                changed=False,
                audit_entries=audit_entries,
                msg="Audit log retrieved successfully"
            )
            
    except requests.exceptions.RequestException as e:
        module.fail_json(msg=f"API request failed: {str(e)}")
    except Exception as e:
        module.fail_json(msg=f"Unexpected error: {str(e)}")

if __name__ == '__main__':
    main()

# Usage in playbook
---
- name: Manage HSM keys
  hosts: security_infrastructure
  
  tasks:
    - name: Rotate encryption key
      hsm_key_manager:
        api_endpoint: "hsm.internal.example.com"
        api_key: "{{ vault_hsm_api_key }}"
        action: rotate
        key_id: "key-encryption-primary"
        new_algorithm: "AES-256-GCM"
      register: rotation_result
      
    - name: Verify key fingerprint
      hsm_key_manager:
        api_endpoint: "hsm.internal.example.com"
        api_key: "{{ vault_hsm_api_key }}"
        action: verify
        key_id: "key-encryption-primary"
        expected_fingerprint: "{{ expected_key_fingerprint }}"
      register: verification
      
    - name: Audit key access (last 30 days)
      hsm_key_manager:
        api_endpoint: "hsm.internal.example.com"
        api_key: "{{ vault_hsm_api_key }}"
        action: audit
        key_id: "key-encryption-primary"
        audit_days: 30
      register: audit_log
      
    - name: Generate compliance report
      template:
        src: hsm_compliance_report.j2
        dest: "/var/reports/hsm_compliance_{{ now(utc=True).strftime('%Y%m%d') }}.txt"
      vars:
        audit_entries: "{{ audit_log.audit_entries }}"
```

**Best Practices Applied**

1. **Module Structure**: Clear separation of concerns with class-based design
2. **Error Handling**: Comprehensive error handling with meaningful messages
3. **Async Support**: Module supports Ansible's async operations for long operations
4. **Idempotency**: Idempotent operations (verify doesn't change state)
5. **Security**: Sensitive parameters marked with `no_log: True`
6. **Documentation**: Clear parameter documentation and examples
7. **Testing**: Module includes validation of input parameters

---

## Interview Questions

### Interview Question 1: Explain Variable Precedence

**Question**: You're debugging a playbook where a variable has different values in dev, staging, and production. A developer defined the same variable in:
- `roles/app_deploy/defaults/main.yml`
- `group_vars/all/common.yml`
- `group_vars/production/main.yml`
- A playbook `vars:` section
- An Ansible CLI `-e` flag

For a production host, which source actually wins? Walk me through how you'd debug this in a production environment without stopping the deployment.

**Expected Answer (Senior Level)**

*A senior engineer should understand the precedence order and explain the operational implications:*

**Precedence Order (highest to lowest):**
1. CLI `-e` flag (highest priority)
2. Playbook `vars:` section
3. Task-level `vars:`
4. Block-level `vars:`
5. Registered variables
6. Facts discovered from hosts
7. Play-scoped variables
8. Block-scoped variables  
9. Task-scoped variables
10. Inventory `host_vars/`
11. Inventory `group_vars/`
12. Role `vars/main.yml`
13. Role `defaults/main.yml` (lowest)

**For the described scenario**: The **CLI `-e` flag wins**. But this is dangerous in production because developers often forget they set an override.

**How I'd Debug Without Stopping Deployment:**

```yaml
- name: Debug variable without impact
  debug:
    var: variable_name
    verbosity: 1              # Only shows with -v flag
    
- name: Log all sources to file
  copy:
    content: |
      Variable Value Sources Debug
      ============================
      
      Final Value: {{ variable_name }}
      
      Source Tracking:
      - Defaults: {{ defaults_value | default('undefined') }}
      - Group vars (all): {{ group_all_value | default('undefined') }}
      - Group vars (production): {{ group_prod_value | default('undefined') }}
      - Playbook vars: {{ playbook_vars_value | default('undefined') }}
      
      Additional Context:
      - Current environment: {{ environment }}
      - Inventory filename: {{ inventory_hostname }}
      - Effective hostname: {{ ansible_host }}
    dest: /var/log/variable_debug_{{ now(utc=True).strftime('%s') }}.log
```

This logs the final value without affecting deployment.

**Operational Red Flag**: If you're relying on precedence to win arguments, your architecture is wrong. Better approach: explicit variable hierarchy with clear names:

```yaml
# base_port: 8080 (from defaults)
# org_standard_port: 8080 (org-wide standard)
# env_production_port: 80 (production override)

# Usage: 
app_port: "{{ env_production_port | default(org_standard_port, true) | default(base_port, true) }}"
```

This is explicit, debuggable, and doesn't rely on Ansible's precedence confusion.

---

### Interview Question 2: Designing a Collection for Multi-Team Organization

**Question**: Your organization has 50+ infrastructure automation playbooks scattered across 10 teams. You want to consolidate them into a shared collection to enable standardization. What's your architecture? How do you handle:
- Version management across teams
- Backward compatibility when making changes
- Preventing one team's change from breaking another team's playbooks
- Testing before release

**Expected Answer (Senior Level)**

**Collection Architecture Design:**

```yaml
# Galaxy.yml versioning strategy
namespace: myorg
name: infrastructure
version: "3.2.1"

# Version semantics:
# MAJOR: API-breaking changes (rare, coordinated across teams)
# MINOR: New features, backward compatible
# PATCH: Bug fixes, no API changes

dependencies:
  community.aws: ">=5.0.0,<6.0.0"    # Constrained version
  kubernetes.core: "2.4.0"            # Pin critical deps
```

**Breaking Change Management Protocol:**

```
Scenario: Removing deprecated parameter from role

RULE 1: Never remove APIs abruptly
- Deprecate in version N with warning
- Continue supporting in N+1
- Remove in N+2 (minimum 2 releases)

Implementation:
v3.0.0:
- Parameter removed → BREAKS API → DON'T DO THIS

v3.0.0 (correct):
- Add new parameter: vpc_identifier  
- Keep old parameter: vpc_name (deprecated)
- Log deprecation warning

v3.1.0:
- Still supports both parameters
- Deprecation warning continued

v3.2.0:
- Remove vpc_name parameter
- Update documentation

COMMUNICATION:
- Changelog entry in v3.0.0: "vpc_name deprecated; use vpc_identifier"
- Required version bump to 3.x (MINOR, not PATCH)
- Announce in team meeting before release
```

**Testing Strategy:**

```yaml
# tests/test_vpc_provisioner.yml
---
- name: Test backward compatibility
  hosts: localhost
  gather_facts: no
  
  tasks:
    - name: Test new variable name
      import_role:
        name: vpc_provisioner
      vars:
        vpc_identifier: "test-vpc"
        
    - name: Test old variable name (deprecated)
      import_role:
        name: vpc_provisioner
      vars:
        vpc_name: "legacy-vpc"
        
    - name: Test precedence (both provided)
      import_role:
        name: vpc_provisioner
      vars:
        vpc_identifier: "new-vpc"
        vpc_name: "old-vpc"

# CI/CD pipeline runs these tests before release
```

**Multi-Team Coordination:**

```yaml
# requirements.yml in each team's deployment
---
collections:
  - name: myorg.infrastructure
    version: "3.0.*"            # Allow PATCH updates (auto-fixes)
    
  # Team-specific collections pinned exactly
  - name: team_a.proprietary
    version: "1.2.3"
    source: https://artifactory.internal

# Updates safely:
# 3.0.0 → 3.0.1 (auto-patch bug fix, safe)
# 3.0.0 → 3.1.0 (manual—new features, review needed)
```

**Preventing Cross-Team Breakage:**

```yaml
# Rule 1: Namespacing
# Team A's custom module: myorg.infrastructure.team_a_deploy
# Team B's custom module: myorg.infrastructure.team_b_deploy
# No collision; each team owns its namespace

# Rule 2: Dependency documentation
# roles/vpc_provisioner/meta/main.yml
argument_specs:
  main:
    short_description: Provision AWS VPC
    options:
      vpc_identifier:
        description: VPC name identifier
        type: str
        required: true
        example: "prod-vpc"

# Rule 3: Explicit versioning
# If Team A needs features from v3.2.0 but Team B requires v3.0.x:
collections:
  - name: myorg.infrastructure
    version: "3.2.0"
```

---

### Interview Question 3: Custom Module Security Considerations

**Question**: You're developing a custom Ansible module that manages secrets (database passwords, API keys). What security considerations must you implement? What attacks are you protecting against?

**Expected Answer (Senior Level)**

**Security Architecture for Secret-Handling Module:**

```python
# Key Security Considerations:

1. CREDENTIAL PROTECTION
❌ WRONG:
def set_password(new_password):
    result = {
        'changed': True,
        'password': new_password,  # LEAKED in output!
        'entered_password': new_password  # LEAKED
    }

✅ CORRECT:
def set_password(new_password):
    result = {
        'changed': True
        # Never return credentials in output
    }
    # Password confirmed via hash comparison only

2. TRANSMISSION SECURITY
❌ WRONG:
import http.client
conn = http.client.HTTPConnection("api.example.com")  # Unencrypted!

✅ CORRECT:
import ssl
context = ssl.create_default_context(ssl.Purpose.SERVER_AUTH)
context.check_hostname = True
context.verify_mode = ssl.CERT_REQUIRED
# Uses requests library with SSL verification by default

3. MODULE ARGUMENT PROTECTION
module = AnsibleModule(
    argument_spec=dict(
        api_key=dict(
            type='str',
            no_log=True            # ← CRITICAL: prevents logging
        ),
        password=dict(
            type='str',
            no_log=True            # ← Hides from ansible-playbook output
        )
    )
)

4. AVOIDING TIMING ATTACKS
❌ WRONG:
if user_input == stored_password:
    # Simple string comparison can be timed-attacked
    
✅ CORRECT:
import hmac
if hmac.compare_digest(user_input, stored_password):
    # Time-constant comparison

5. INJECTION ATTACK PREVENTION
❌ WRONG:
os.system(f"aws s3 cp {user_file}")  # Command injection!

✅ CORRECT:
import subprocess
import shlex
result = subprocess.run(
    ["aws", "s3", "cp", user_file],  # Parameters as list, not string
    capture_output=True
)

6. AUDIT LOGGING (WITHOUT EXPOSING SECRETS)
# Log actions, not values
module.log("Password rotation initiated for user: {{ username }}")
# Good: User identity logged

# NOT:
module.log("Setting password to: {{ password }}")
# Bad: Credential logged
```

**Threat Models:**

```
Threat 1: Credential in Ansible output
Attack: Run ansible-playbook, credentials captured in stdout/logs
Defense: no_log=True, never return secrets in module result

Threat 2: MITM (Man-in-the-Middle)
Attack: Intercept API calls, steal credentials in transit
Defense: SSL/TLS verification, certificate pinning for critical APIs

Threat 3: Playbook checked into Git
Attack: Git history exposes removed secrets
Defense: Use vault, external secret managers, encourage .gitignore secrets

Threat 4: Module logs written to disk
Attack: Read /var/log/ or Ansible callback logs to steal credentials
Defense: no_log=True prevents logging

Threat 5: Timing attacks on password validation
Attack: Measure response time to guess password character-by-character
Defense: Use constant-time comparison (hmac.compare_digest)

Threat 6: Shell injection via module parameters
Attack: Pass shell meta-characters in parameters to execute arbitrary code
Defense: Use structured API calls (boto3, requests) not shell commands
```

**Best Practices Summary:**

```yaml
# Module development checklist for secrets:

- [ ] All credential parameters use no_log=True
- [ ] Module never returns secrets in exit_json/fail_json
- [ ] API calls use HTTPS with certificate verification
- [ ] Sensitive comparisons use hmac.compare_digest()
- [ ] No subprocess/shell calls; use structured APIs
- [ ] Audit logging only logs actions, not values
- [ ] Module documented with security warnings
- [ ] Tested with Ansible vault integration
- [ ] Callback plugins configured to strip secrets from logs
```

---

### Interview Question 4: Multi-Environment Configuration Strategy

**Question**: Design how you'd structure variables and configuration for a company deploying to AWS, Azure, and GCP with separate dev, staging, and production environments. How do you prevent mistakes like deploying staging config to production?

**Expected Answer (Senior Level)**

**Multi-Cloud, Multi-Environment Architecture:**

```
Inventory Structure:
inventory/
├── hosts.yml                          # Master inventory
├── group_vars/
│   ├── all/                          # Applied to ALL (global defaults)
│   │   ├── common.yml               # Org-wide constants
│   │   └── security_baseline.yml    # Compliance baseline
│   ├── clouds/                      # Cloud provider grouping
│   │   ├── aws/
│   │   │   └── aws_defaults.yml
│   │   ├── azure/
│   │   │   └── azure_defaults.yml
│   │   └── gcp/
│   │       └── gcp_defaults.yml
│   ├── environments/                # CRITICAL: Environment isolation
│   │   ├── dev/
│   │   │   ├── main.yml
│   │   │   └── secrets.yml (vault)
│   │   ├── staging/
│   │   │   ├── main.yml
│   │   │   └── secrets.yml (vault)
│   │   └── production/
│   │       ├── main.yml
│   │       └── secrets.yml (vault-encrypted)
│   ├── regions/
│   │   ├── aws_us_east_1/
│   │   ├── aws_us_west_2/
│   │   ├── azure_eastus/
│   │   └── gcp_us_central1/
│   └── applications/
│       ├── app_web_tier/
│       ├── app_database/
│       └── app_cache/
└── host_vars/              # Individual host overrides (rarely used)

hosts.yml Structure (Nested Groups for Hierarchy):

[local]
localhost ansible_connection=local

[aws:children]
aws_dev
aws_staging
aws_production

[aws_dev:children]
aws_dev_us_east_1

[aws_dev_us_east_1]
dev_web_01 app_name=web_tier
dev_db_01 app_name=database

[aws_staging:children]
aws_staging_us_east_1

[aws_production:children]
aws_prod_us_east_1
aws_prod_us_west_2

[azure:children]
azure_dev
azure_staging
azure_production

[gcp:children]
gcp_dev
gcp_staging
gcp_production

[environments:children]
dev
staging
production

[dev:children]
aws_dev
azure_dev
gcp_dev

[staging:children]
aws_staging
azure_staging
gcp_staging

[production:children]
aws_production
azure_production
gcp_production
```

**Preventing Cross-Environment Mistakes:**

```yaml
# Playbook-level safeguards
---
- name: Deploy application
  hosts: "{{ target_environment }}"
  gather_facts: yes
  
  # SAFETY MECHANISM 1: Explicit environment confirmation
  pre_tasks:
    - name: Confirm target environment
      pause:
        prompt: |
          ⚠️  WARNING: Deploying to {{ environment_type }}
          
          Environment: {{ environment_type | upper }}
          Target hosts: {{ play_hosts | length }} hosts
          
          Type 'YES' to proceed or 'NO' to abort:
      register: confirmation
      when: environment_type == 'production'
      
    - name: Abort if not confirmed
      assert:
        that:
          - confirmation.user_input | upper == 'YES'
        fail_msg: "Production deployment cancelled"
      when: environment_type == 'production'
    
    # SAFETY MECHANISM 2: Validate configuration matches environment
    - name: Validate environment variables loaded correctly
      assert:
        that:
          - inventory_hostname in groups[environment_type]
          - environment_type in ['dev', 'staging', 'production']
          - resource_tier_configs[environment_type] is defined
        fail_msg: |
          Configuration mismatch!
          Expected env: {{ environment_type }}
          Host groups: {{ group_names }}
      
    # SAFETY MECHANISM 3: Prevent mixing configuration sources
    - name: Detect config source mismatches
      block:
        - name: Check group_vars matches environment
          assert:
            that:
              - lookup('first_found', {
                  'files': [
                    'group_vars/environments/{{ environment_type }}/main.yml',
                    'group_vars/environments/dev/main.yml'
                  ]
                }) is search(environment_type)
            fail_msg: |
              Group vars don't match environment!
              May be loading wrong configuration.
      rescue:
        - debug:
            msg: "Configuration validation warning (non-blocking)"
      
  roles:
    - role: deploy_application
      vars:
        # Explicit variable source to prevent accidents
        app_replicas: "{{ environment_specific_replicas[environment_type] }}"
        backup_enabled: "{{ environment_backup_policies[environment_type] }}"
        monitoring_retention: "{{ environment_log_retention[environment_type] }}"
```

**Prevent Production Accidents with RBAC:**

```yaml
# ansible.cfg - Restrict production access
[defaults]
# Only allow production deployment from specific hosts
# Prevent developers from running prod playbooks locally

# Use inventory constraints:
# - Production inventory only accessible to CI/CD service accounts
# - Vault keys for production environments stored separately
# - Production credentials require MFA

# roles/production_deploy_verify/tasks/main.yml
---
- name: Verify production deployment eligibility
  block:
    - name: Check if running from approved CI/CD
      assert:
        that:
          - ansible_user_id == 'ci-orchestration'
          - ansible_host_group == 'ci-runners'
          - environment_type == 'production'
        fail_msg: |
          ❌ PRODUCTION DEPLOYMENT BLOCKED
          
          Only CI/CD service accounts can deploy to production.
          Local deployments not allowed.
          
          Current user: {{ ansible_user_id }}
          Expected: ci-orchestration
          
      when: environment_type == 'production'
```

---

### Interview Question 5: Async Task Orchestration for Long-Running Operations

**Question**: You need to deploy updates to 200 database servers. Each update involves:
1. Backup (30 min)
2. Apply schema migrations (10 min)
3. Verify data integrity (20 min)
4. Health check (5 min)

Total: ~65 minutes per server serially. How do you orchestrate this to minimize deployment window while maintaining safety?

**Expected Answer (Senior Level)**

**Orchestration Strategy:**

```yaml
---
- name: Database deployment with async orchestration
  hosts: db_servers
  gather_facts: no
  
  vars:
    # Batch deployment: 10 servers in parallel
    batch_size: 10
    backup_timeout: 1800          # 30 min
    migration_timeout: 600        # 10 min
    verify_timeout: 1200          # 20 min
    health_check_timeout: 300     # 5 min
    
  serial: "{{ batch_size }}"      # Rolling 10 at a time
  
  pre_tasks:
    - name: Pre-deployment snapshot
      block:
        - name: Snapshot database state
          command: /usr/local/bin/db_snapshot.sh
          register: pre_snapshot
          failed_when: pre_snapshot.rc != 0
          
        - name: Store snapshot for rollback
          set_fact:
            db_pre_snapshot_path: "{{ pre_snapshot.stdout }}"
            
  tasks:
    # PHASE 1: Start all backups asynchronously (no waiting)
    - name: Start database backup (async)
      block:
        - name: Initiate backup
          command: /usr/local/bin/db_backup.sh
          async: "{{ backup_timeout }}"         # Timeout after 30 min
          poll: 0                               # Don't wait
          register: backup_job
          
    # PHASE 2: While backups run, prepare schema in parallel
    - name: Prepare schema migration resources
      block:
        - name: Validate schema migrations
          command: /usr/local/bin/validate_migrations.sh
          register: migration_validation
          
        - name: Pre-stage migration files
          copy:
            src: "migrations/{{ target_version }}/"
            dest: /opt/db/pending_migrations/
            
    # PHASE 3: Monitor backup and prepare for migration
    - name: Monitor backup completion
      async_status:
        jid: "{{ backup_job.ansible_job_id }}"
      register: backup_status
      until: backup_status.finished
      retries: 180
      delay: 10
      
    - name: Validate backup integrity
      command: /usr/local/bin/verify_backup.sh "{{ backup_job.stdout }}"
      register: backup_verify
      failed_when: backup_verify.rc != 0
      
    # PHASE 4: Apply schema migrations
    - name: Apply schema migrations (with timeout)
      block:
        - name: Start migration
          command: /usr/local/bin/apply_migrations.sh "{{ target_version }}"
          async: "{{ migration_timeout }}"
          poll: 0
          register: migration_job
          
        - name: Monitor migration progress
          command: /usr/local/bin/check_migration_status.sh
          register: migration_check
          until: migration_check.stdout | regex_search('completed')
          retries: 60
          delay: 10
          failed_when: migration_check.stdout | regex_search('failed')
          
    # PHASE 5: Verify data integrity
    - name: Perform data integrity checks
      block:
        - name: Start integrity verification
          command: /usr/local/bin/verify_data_integrity.sh
          async: "{{ verify_timeout }}"
          poll: 0
          register: verify_job
          
        - name: Monitor verification
          async_status:
            jid: "{{ verify_job.ansible_job_id }}"
          register: verify_status
          until: verify_status.finished
          retries: 120
          delay: 10
          
    # PHASE 6: Final health checks
    - name: Health check and validation
      block:
        - name: Perform application health checks
          uri:
            url: "http://{{ inventory_hostname }}:3306/health"
            method: GET
            status_code: 200
          retries: 10
          delay: 5
          register: health_check
          
        - name: Verify replication lag (if applicable)
          command: /usr/local/bin/check_replication_lag.sh
          register: replication_check
          failed_when: replication_check.stdout | int > 10
          # Fail if lag > 10 seconds
          
      rescue:
        - name: Trigger rollback on health failure
          command: /usr/local/bin/rollback_to_snapshot.sh "{{ db_pre_snapshot_path }}"
          register: rollback_result
          
        - name: Fail play after rollback
          fail:
            msg: "Health checks failed; database rolled back to pre-deployment state"
            
  post_tasks:
    - name: Record deployment metrics
      set_fact:
        deployment_metrics:
          server: "{{ inventory_hostname }}"
          target_version: "{{ target_version }}"
          backup_duration: "{{ backup_status.duration | default(0) }}"
          migration_duration: "{{ migration_check.duration | default(0) }}"
          total_duration: "{{ (now() - play_start_time).total_seconds() }}"
          status: "success"
          
    - name: Pause between batches for observation
      pause:
        seconds: 60
      when: inventory_hostname != ansible_play_hosts[-1]
      # Don't pause after last batch

# Timeline Optimization:
# Batch 1 (servers 1-10):
#   0 min:    Start backups (async)
#   5 min:    Start schema prep while backups run
#   30 min:   Backups finish; start migrations
#   40 min:   Migrations finish; start verification
#   60 min:   Verification finish; health checks pass
#   Total:    ~65 minutes
#
# Batch 2 (servers 11-20) starts immediately after Batch 1:
#   65 min:   Batch 2 starts
#   130 min:  Batch 2 completes
#   ...
#
# 20 batches × 65 min = 1,300 min for all 200 servers
# (vs. 200 × 65 = 13,000 min serially)
# Speedup: 10x faster (matches batch size)
```

---

### Interview Question 6: Role Dependencies and Composition

**Question**: You need to create a role that sets up a Kubernetes worker node. The node depends on: base OS configuration, container runtime, kubelet. Kubelet depends on: container runtime configured, system kernel properly tuned. How do you declare these dependencies? What problems can occur?

**Expected Answer (Senior Level)**

**Dependency Declaration with meta/main.yml:**

```yaml
# roles/kubernetes_worker/meta/main.yml
---
dependencies:
  # First: OS base configuration (independent)
  - role: common_os_hardening
    tags: [base]
    
  # Second: Container runtime (depends on OS being ready)
  - role: container_runtime
    tags: [runtime]
    when: container_runtime_enabled | default(true)
    vars:
      runtime_version: "{{ container_runtime_version }}"
      
  # Third: Kernel tuning (independent of container runtime)
  - role: kernel_tuning
    tags: [performance]
    when: enable_performance_tuning | default(true)
    
  # Fourth: Kubelet (depends on both runtime and kernel tuning)
  - role: kubelet_install
    tags: [kubelet]
    
  # Fifth: Kubelet configuration (depends on Kubelet installed)
  - role: kubelet_configure
    tags: [kubelet]

# Execution order (inferred from declaration):
# 1. common_os_hardening
# 2. container_runtime (with vars)
# 3. kernel_tuning
# 4. kubelet_install
# 5. kubelet_configure
# 6. kubernetes_worker (main role tasks)
```

**Common Pitfalls and Solutions:**

```yaml
# PITFALL 1: Circular Dependencies
# roles/A/meta/main.yml
dependencies:
  - role: B
  
# roles/B/meta/main.yml
dependencies:
  - role: A
  
# Result: Ansible hangs or errors. Detected at runtime.
# Solution: Use role in separate plays instead of dependencies

---
- name: Install base
  hosts: all
  roles:
    - role: A
    
- name: Install dependent
  hosts: all
  roles:
    - role: B
    # Now clear dependency order

# PITFALL 2: Dependency with Conflicting Variables
# roles/app_deploy/meta/main.yml
dependencies:
  - role: nginx
    vars:
      nginx_worker_processes: 8

# roles/nginx/defaults/main.yml
nginx_worker_processes: 4

# Problem: Is it 8 or 4? Precedence means...
# - If consuming role passes `nginx_worker_processes: 16` in vars:
#   16 wins (highest precedence)
# - If only dependency passes 8:
#   8 wins (role vars > defaults)

# Solution: Document variable precedence clearly
# roles/kubernetes_worker/README.md:
# "If you override nginx_worker_processes in your playbook,
#  it takes precedence over our dependency."

# PITFALL 3: Conditional Dependencies
# roles/kubernetes_worker/meta/main.yml
dependencies:
  - role: nvidia_gpu_driver
    when: gpu_enabled | default(false)
    # ← This DOESN'T WORK! Dependencies always execute

# Solution: Move conditional to role's own tasks
# roles/kubernetes_worker/tasks/main.yml
---
- name: Setup GPU support
  include_role:
    name: nvidia_gpu_driver
    apply:
      tags: [gpu]
  when: gpu_enabled | default(false)

# PITFALL 4: Version Conflicts in Dependencies
# roles/kubernetes_worker/meta/main.yml
dependencies:
  - role: container_runtime
    vars:
      runtime_version: "20.10"

# roles/container_runtime/defaults/main.yml
runtime_version: "19.03"  # Old version!

# Kubernetes worker needs 20.10 but gets 19.03
# Solution: Pin in multiple places and validate

# roles/kubernetes_worker/tasks/main.yml
---
- name: Validate container runtime version
  assert:
    that:
      - container_runtime_version >= "20.10"
    fail_msg: |
      Container runtime version {{ container_runtime_version }} 
      is too old. Must be >= 20.10 for Kubernetes compatibility
```

**Best Practices:**

```yaml
# BEST PRACTICE: Explicit dependency contract
# roles/kubernetes_worker/meta/main.yml
---
dependencies:
  - role: container_runtime
    tags: [base, runtime]
    vars:
      # EXPLICIT: Pass required versions
      runtime_version: "{{ kubernetes_worker_runtime_version }}"
      runtime_cgroup_driver: "systemd"      # Required for K8s
      
  - role: kernel_tuning
    vars:
      # EXPLICIT: Kernel settings required for kubelet
      required_kernel_params:
        - net.bridge.bridge-nf-call-iptables=1
        - net.ipv4.ip_forward=1

# roles/kubernetes_worker/defaults/main.yml
---
# DECLARE what versions are needed
kubernetes_worker_runtime_version: "20.10"
kubernetes_worker_kubelet_version: "1.24"

# roles/kubernetes_worker/tasks/main.yml
---
- name: Validate dependency versions
  assert:
    that:
      - container_runtime_version >= kubernetes_worker_runtime_version
      - kubelet_version >= kubernetes_worker_kubelet_version
    fail_msg: |
      Dependencies don't meet requirements
      Runtime: {{ container_runtime_version }} (need >= {{ kubernetes_worker_runtime_version }})
      Kubelet: {{ kubelet_version }} (need >= {{ kubernetes_worker_kubelet_version }})
```

---

### Interview Question 7: Debugging Jinja2 Template Rendering Issues

**Question**: You have a template that generates a complex NGINX configuration file. The rendered output has syntax errors—NGINX won't start. How do you debug this? What techniques isolate whether the issue is in Jinja2 rendering or the template logic itself?

**Expected Answer (Senior Level)**

**Debugging Jinja2 Template Issues:**

```yaml
# Strategy 1: Render to debug file instead of deploying
---
- name: Debug template rendering
  hosts: all
  
  tasks:
    # STEP 1: Render to temporary file for inspection
    - name: Render template without deploying
      template:
        src: nginx.conf.j2
        dest: /tmp/nginx.conf.debug
        mode: "0644"
      register: template_render
      
    - name: Display entire rendered output
      ansible.builtin.debug:
        msg: "{{ lookup('file', '/tmp/nginx.conf.debug') }}"
      
    # STEP 2: Syntax check the rendered file
    - name: Validate NGINX syntax
      command: nginx -t -c /tmp/nginx.conf.debug
      register: syntax_check
      failed_when: false
      changed_when: false
      
    - name: Display syntax check results
      debug:
        msg: "{{ syntax_check.stdout }}\n{{ syntax_check.stderr }}"

# Strategy 2: Break down Jinja2 template piece by piece
# templates/nginx.conf.j2 (original problematic template)
upstream backend {
    {% for server in backend_servers %}
    server {{ server }} max_fails=3;
    {% endfor %}
}

# Debug version: Isolate sections
# templates/nginx.conf.debug.j2
# Test: Are backend_servers defined?
# Value of backend_servers: {{ backend_servers }}

upstream backend {
    {% if backend_servers | length > 0 %}
        {% for server in backend_servers %}
            # Server entry: {{ server }}
            server {{ server }} max_fails=3;
        {% endfor %}
    {% else %}
        # WARNING: backend_servers is empty!
        server 127.0.0.1:9000;
    {% endif %}
}

# Debugging playbook
- name: Debug template variables
  debug:
    msg: |
      Template Debug Report
      ====================
      
      backend_servers: {{ backend_servers | default('UNDEFINED') }}
      backend_servers length: {{ backend_servers | length | default('UNDEFINED') }}
      
      backend_servers content:
      {% for srv in backend_servers %}
      - {{ srv }}
      {% endfor %}
      
      Type check: {{ backend_servers | type_debug }}
      
# Strategy 3: Use Jinja2's error reporting
- name: Render with error details
  block:
    - name: Template render
      template:
        src: nginx.conf.j2
        dest: /tmp/nginx.conf
      register: template_result
      
  rescue:
    - name: Display template error
      debug:
        msg: |
          Template Rendering Error
          ========================
          
          Error: {{ ansible_failed_result.msg }}
          
          This typically indicates:
          - Undefined variable used in template
          - Invalid filter syntax (| filter_name)
          - Jinja2 syntax error ({% if %} not closed)
          
          Suggested fix:
          1. Check variable definition in defaults/vars
          2. Validate filter name is correct
          3. Check Jinja2 syntax (balance if/endif, for/endfor)

# Strategy 4: Add explicit type validation in template
# templates/nginx.conf.j2 with validation:
{% set validated_servers = [] %}
{% for server in backend_servers | default([]) %}
    {% if server is string %}
        {% set _ = validated_servers.append(server) %}
    {% else %}
        # WARNING: Invalid server type at index {{ loop.index0 }}: {{ server | type_debug }}
    {% endif %}
{% endfor %}

upstream backend {
    {% for server in validated_servers %}
    server {{ server }} max_fails=3;
    {% endfor %}
}

# Strategy 5: Separate variable computation from template
# roles/nginx/tasks/main.yml
---
- name: Compute upstream servers
  set_fact:
    computed_upstream_servers: |
      {%- set servers = [] -%}
      {%- for host in groups['backend'] -%}
          {%- set _ = servers.append(hostvars[host].ansible_host + ':8000') -%}
      {%- endfor -%}
      {{- servers -}}
    
- name: Validate computed servers
  assert:
    that:
      - computed_upstream_servers | length > 0
      - computed_upstream_servers[0] is string
    fail_msg: "Upstream server computation failed"
    
- name: Render template with validated data
  template:
    src: nginx.conf.j2
    dest: /etc/nginx/nginx.conf
  vars:
    backend_servers: "{{ computed_upstream_servers }}"
```

**Debugging Checklist:**

```yaml
Template Issues Diagnostic:

1. Is variable defined?
   {{ variable | default('UNDEFINED') }}
   
2. Is variable correct type?
   {{ variable | type_debug }}
   
3. Is variable has expected value?
   {{ variable }}
   
4. Is loop iteration working?
   {% for item in list %}
   Item {{ loop.index }}: {{ item }}
   {% endfor %}
   
5. Is conditional logic correct?
   {% if condition %}
   True branch executed
   {% else %}
   False branch executed
   {% endif %}
   
6. Is Jinja2 syntax valid?
   - All {% if %} have {% endif %}
   - All {% for %} have {% endfor %}
   - No mismatched { or }
   
7. Is filter syntax correct?
   {{ variable | filter_name(arg1, arg2) }}
   NOT: {{ variable | filter_name arg1 arg2 }}
```

---

### Interview Question 8: Production Incident Response with Ansible

**Question**: You have a critical incident: A bad playbook run left your database in an inconsistent state. You need to:
1. Immediately stop further damage
2. Understand what changed
3. Restore to last known good state
4. Verify everything works
5. Brief management in 5 minutes

Walk me through your Ansible-based response.

**Expected Answer (Senior Level)**

**Incident Response Playbook:**

```yaml
# playbooks/incident_response.yml
---
- name: Critical Incident Response - Database Inconsistency
  hosts: db_primary
  gather_facts: yes
  become: yes
  
  vars:
    incident_id: "{{ now(utc=True).strftime('%Y%m%d_%H%M%S') }}"
    incident_severity: critical
    last_known_good_backup: "/backups/db_2024_01_15_020000.tar.gz"
    slack_webhook: "{{ vault_slack_incident_webhook }}"
    
  pre_tasks:
    # STEP 1: STOP THE BLEEDING
    - name: Immediate damage control
      block:
        - name: Kill all running playbooks
          shell: pkill -f "ansible-playbook"
          ignore_errors: yes
          
        - name: Pause database replication
          mysql_replication:
            mode: stopslave
            
        - name: Freeze database writes
          command: mysql -e "SET GLOBAL read_only=ON;"
          
        - name: Alert on-call team immediately
          uri:
            url: "{{ slack_webhook }}"
            method: POST
            body_format: json
            body:
              text: "🚨 CRITICAL INCIDENT: Database inconsistency detected"
              attachments:
                - color: "danger"
                  text: |
                    Incident ID: {{ incident_id }}
                    Severity: {{ incident_severity }}
                    Time: {{ now(utc=True).isoformat() }}
                    Action: Database frozen. Incident response initiated.
          ignore_errors: yes
          
    # STEP 2: FORENSICS - UNDERSTAND WHAT HAPPENED
    - name: Collect forensic data
      block:
        - name: Capture current database state
          block:
            - name: Query database status
              mysql_query:
                query: "SHOW MASTER STATUS\G"
              register: db_status
              
            - name: Check for inconsistencies
              mysql_query:
                query: "CHECK TABLE {{ item }} QUICK;"
              loop: "{{ database_tables }}"
              register: check_results
              ignore_errors: yes
              
            - name: Query recent queries log
              shell: "tail -1000 /var/log/mysql/general.log | grep -E 'Query|Update|Insert|Delete' > /tmp/recent_queries_{{ incident_id }}.log"
              
        - name: Capture Ansible playbook history
          block:
            - name: Get last executed playbook
              shell: "ls -lt ~/.ansible/playbooks/*.log 2>/dev/null | head -1 | awk '{print $NF}'"
              register: last_playbook_log
              
            - name: Extract playbook details
              shell: "head -50 {{ last_playbook_log.stdout }}"
              register: playbook_details
              
        - name: Store forensic data
          copy:
            content: |
              INCIDENT FORENSICS
              ==================
              
              Incident ID: {{ incident_id }}
              Time: {{ now(utc=True).isoformat() }}
              
              Database Status:
              {{ db_status.query_result[0] }}
              
              Table Check Results:
              {% for result in check_results.results %}
              - {{ result.query_result }}
              {% endfor %}
              
              Recent Queries:
              {{ lookup('file', '/tmp/recent_queries_' + incident_id + '.log') }}
              
              Last Playbook:
              {{ playbook_details.stdout }}
            dest: "/var/log/incidents/forensics_{{ incident_id }}.log"
            
    # STEP 3: RESTORE TO LAST KNOWN GOOD STATE
    - name: Restore database
      block:
        - name: Verify backup exists and is readable
          stat:
            path: "{{ last_known_good_backup }}"
          register: backup_stat
          failed_when: not backup_stat.stat.exists
          
        - name: Create restore point snapshot
          shell: "cp -p {{ last_known_good_backup }} /backups/pre_restore_{{ incident_id }}.tar.gz"
          
        - name: Stop MySQL
          systemd:
            name: mysql
            state: stopped
            
        - name: Restore database from backup
          shell: |
            cd /var/lib/mysql
            tar -xzf {{ last_known_good_backup }}
            chown -R mysql:mysql /var/lib/mysql
            
        - name: Start MySQL
          systemd:
            name: mysql
            state: started
          register: mysql_start
          
        - name: Wait for MySQL to be ready
          wait_for:
            port: 3306
            delay: 5
            timeout: 30
            
        - name: Verify restore integrity
          mysql_query:
            query: "SHOW TABLES;"
          register: table_list
          failed_when: table_list.query_result | length == 0
          
    # STEP 4: VALIDATION & VERIFICATION
    - name: Post-restore validation
      block:
        - name: Run consistency checks
          mysql_query:
            query: "CHECK TABLE {{ item }} EXTENDED;"
          loop: "{{ database_tables }}"
          register: check_restore
          
        - name: Verify data wasn't corrupted
          mysql_query:
            query: "SELECT COUNT(*) FROM {{ item }};"
          loop: "{{ database_tables }}"
          register: row_counts
          
        - name: Test application connectivity
          mysql_user:
            name: "{{ app_db_user }}"
            host: "{{ app_server_ip }}"
            password: "{{ vault_app_db_password }}"
            state: present
            
        - name: Run application health check
          uri:
            url: "http://{{ app_server_ip }}:8080/healthz"
            method: GET
            status_code: 200
          retries: 5
          delay: 5
          
    # STEP 5: COMMUNICATE STATUS
    - name: Generate incident report
      copy:
        content: |
          INCIDENT RESPONSE REPORT
          ========================
          
          Incident ID: {{ incident_id }}
          Severity: {{ incident_severity }}
          Detection Time: {{ now(utc=True).isoformat() }}
          Resolution Time: {{ (now() - play_start_time).total_seconds() }} seconds
          
          Actions Taken:
          ✓ Stopped all playbooks (damage control)
          ✓ Froze database writes (prevent further corruption)
          ✓ Collected forensic data ({{ incident_id }})
          ✓ Restored from last known good backup ({{ last_known_good_backup }})
          ✓ Verified data integrity ({{ row_counts.results | length }} tables checked)
          ✓ Validated application connectivity (health checks passed)
          
          Status: RESOLVED ✓
          
          Next Steps:
          1. Root cause analysis on failed playbook
          2. Code review process enhancement
          3. Automated testing before production deployment
          4. Post-mortem meeting (24 hours)
          
          Key Metrics:
          - Detection lag: < 2 minutes
          - Resolution time: {{ (now() - play_start_time).total_seconds() }} seconds
          - Data loss: None
          - System downtime: {{ downtime_minutes }} minutes
        dest: "/var/log/incidents/report_{{ incident_id }}.md"
        
    - name: Notify stakeholders
      uri:
        url: "{{ slack_webhook }}"
        method: POST
        body_format: json
        body:
          text: "✅ INCIDENT RESOLVED: Database restored and validated"
          attachments:
            - color: "good"
              fields:
                - title: "Incident ID"
                  value: "{{ incident_id }}"
                - title: "Resolution Time"
                  value: "{{ (now() - play_start_time).total_seconds() }} seconds"
                - title: "Data Loss"
                  value: "None"
                - title: "Next Steps"
                  value: |
                    1. RCA in 1 hour
                    2. Post-mortem in 24 hours
                    3. Report available: {{ incident_id }}
      ignore_errors: yes
```

**5-Minute Brief to Management:**

```
INCIDENT SUMMARY
================

What Happened:
A bad playbook run corrupted the database state.

What We Did:
1. Immediately stopped all operations (2 sec)
2. Froze the database to prevent further damage (5 sec)
3. Restored from last backup (30 sec)
4. Verified all data integrity and application health (45 sec)

Status: FULLY RESOLVED ✓

Impact:
- No data loss
- No customer impact (incident detected and resolved in < 90 seconds)
- Application is fully operational

Root Cause:
- [ ] Under investigation
- [ ] RCA scheduled for 1 hour
- [ ] Process improvements in progress

Next Steps:
- Playbook code review required before production deployment
- Enhanced automated testing in CI/CD pipeline
- Updated runbook for faster response
```

---

### Interview Question 9: Collection Dependency Version Conflicts

**Question**: Your team is building playbooks using two collections:
- `community.aws 5.5.0` (requires Ansible >= 2.10, has security fixes)
- `community.general 4.8.0` (requires Ansible >= 2.11, conflicts with aws 5.5.0)

Your organization runs Ansible 2.10 in some infrastructure, 2.11 in others. How do you handle this?

**Expected Answer (Senior Level)**

**Version Conflict Resolution Strategy:**

```yaml
# Option 1: Version-based playbook selection
---
- name: Detect Ansible version
  hosts: localhost
  gather_facts: no
  
  tasks:
    - name: Check Ansible version
      set_fact:
        ansible_major_version: "{{ ansible_version.major }}"
        ansible_minor_version: "{{ ansible_version.minor }}"
        
    - name: Select appropriate playbook
      include_tasks: "deploy_v{{ ansible_major_version }}_{{ ansible_minor_version }}.yml"
      # Runs deploy_v2_10.yml or deploy_v2_11.yml

# deploy_v2_10.yml
---
- hosts: infrastructure_v2_10
  collections:
    - community.aws:5.5.0
    - name: community.general
      version: "<=4.7.0"        # Compatible version
  # ... playbook tasks

# deploy_v2_11.yml
---
- hosts: infrastructure_v2_11
  collections:
    - community.aws:5.5.0
    - community.general:4.8.0   # Full version available
  # ... playbook tasks

# Option 2: Use most compatible versions
# requirements.yml (safe, backward compatible)
---
collections:
  - name: community.aws
    version: "5.4.0"            # One version back (compatible)
    
  - name: community.general
    version: "4.7.0"            # Confirmed compatible
    
# Option 3: Monorepo with version-specific branches
# ansible/
# ├── branches/
# │   ├── ansible-2.10/
# │   │   ├── requirements.yml (pins compatible versions)
# │   │   └── playbooks/
# │   └── ansible-2.11/
# │       ├── requirements.yml (newer versions)
# │       └── playbooks/

# Option 4: Custom wrapper script
#!/bin/bash
# deploy.sh

ansible_version=$(ansible --version | head -1 | grep -oE '[0-9]+\.[0-9]+')

if [[ "$ansible_version" == "2.10"* ]]; then
    echo "Using Ansible 2.10 compatible collections..."
    ansible-galaxy collection install -r requirements-2.10.yml
    ansible-playbook playbooks/site.yml -i inventory/
elif [[ "$ansible_version" == "2.11"* ]]; then
    echo "Using Ansible 2.11+ compatible collections..."
    ansible-galaxy collection install -r requirements-2.11.yml
    ansible-playbook playbooks/site.yml -i inventory/
else
    echo "Unsupported Ansible version: $ansible_version"
    exit 1
fi
```

**Best Practice: Upgrade Path Management:**

```yaml
# Strategic approach: Phase out old versions

# Phase 1: Support both versions (current)
# All playbooks work with Ansible 2.10+
# requirements.yml pins to compatible versions

# Phase 2: Deprecate old version (3 months)
# Announce: "Ansible 2.10 support ending in Q2 2024"
# requirements.yml still compatible
# Documentation recommends upgrading

# Phase 3: Drop old version (Q2 2024)
# End of support date passed
# requirements.yml requires Ansible >= 2.11
# Old infrastructure must upgrade

# Phase 4: Adopt new features (Q3 2024)
# Collections use 2.11+ features
# Simpler playbooks, better performance

# Communication template:
---
- name: Communicate version requirement change
  debug:
    msg: |
      🔔 ANSIBLE VERSION UPGRADE REQUIRED
      ====================================
      
      Current Support: Ansible 2.10+
      New Requirement (starting Q2 2024): Ansible 2.11+
      
      Why: Newer collections require features only in 2.11+
      
      Action Required:
      1. Test upgrade in dev environment
      2. Plan upgrade for staging (week of Jan 15)
      3. Schedule production upgrade (week of Jan 22)
      
      Timeline:
      - Q1 2024: Both versions supported
      - Q2 2024: Ansible 2.10 deprecated
      - Q3 2024: Ansible 2.10 no longer supported
      
      Support: Reach out to DevOps team for assist
```

---

### Interview Question 10: Monitoring and Observability in IaC

**Question**: Your Ansible playbooks deploy to production twice daily. How do you instrument Ansible to understand:
1. Which deployment took longer than expected?
2. Which hosts failed during deployment?
3. Whether deployments affected system performance (CPU, memory, latency)?
4. Root cause of failures (module issue vs. network vs. target system)?

**Expected Answer (Senior Level)**

**Comprehensive Observability Implementation:**

```yaml
# Approach: Multi-layer observability

# Layer 1: Ansible execution metrics
# ansible.cfg
[defaults]
callback_plugins = ./plugins/callback
callback_log_format = json
callback_whitelist = profile_tasks

# Layer 2: Custom callback plugin
# plugins/callback/observability.py
---
from ansible.plugins.callback import CallbackBase
from ansible.utils.color import colorize_prompt
import json
import time
from datetime import datetime

class CallbackModule(CallbackBase):
    CALLBACK_VERSION = 2.0
    CALLBACK_TYPE = 'stdout'
    CALLBACK_NAME = 'observability'
    
    def __init__(self):
        super(CallbackModule, self).__init__()
        self.play_start_time = None
        self.task_start_time = None
        self.metrics = []
        
    def v2_playbook_on_start(self, playbook):
        self.play_start_time = time.time()
        self._send_metric({
            'event': 'playbook_start',
            'playbook': playbook._file_name,
            'timestamp': datetime.utcnow().isoformat()
        })
        
    def v2_playbook_on_stats(self, stats):
        """Called when playbook finishes"""
        total_time = time.time() - self.play_start_time
        
        # Compile statistics
        processed = stats.processed
        failed = stats.failed
        skipped = stats.skipped
        ok = stats.ok
        
        metrics = {
            'event': 'playbook_complete',
            'duration_seconds': total_time,
            'hosts_processed': len(processed),
            'hosts_failed': len(failed),
            'hosts_skipped': len(skipped),
            'tasks_ok': sum(ok.values()) if ok else 0,
            'tasks_failed': sum(failed.values()) if failed else 0,
            'tasks_skipped': sum(skipped.values()) if skipped else 0,
            'timestamp': datetime.utcnow().isoformat(),
            'success': len(failed) == 0
        }
        
        self._send_metric(metrics)
        
        # Alert if deployment slow
        if total_time > 300:  # > 5 minutes
            self._alert({
                'severity': 'warning',
                'message': f'Deployment took {total_time}s (threshold: 300s)',
                'metrics': metrics
            })
    
    def v2_runner_on_failed(self, result, ignore_errors=False):
        """Called when task fails"""
        self._send_metric({
            'event': 'task_failed',
            'host': result._host.get_name(),
            'task': result._task.get_name(),
            'error_msg': result._result.get('msg', 'Unknown error'),
            'module': result._task.action,
            'timestamp': datetime.utcnow().isoformat()
        })
        
        # Classify failure type
        error_msg = str(result._result.get('msg', ''))
        if 'Connection' in error_msg:
            failure_type = 'network'
        elif 'No such' in error_msg or 'not found' in error_msg:
            failure_type = 'missing_resource'
        elif 'Permission denied' in error_msg:
            failure_type = 'permission'
        else:
            failure_type = 'module_error'
            
        self._send_metric({
            'event': 'failure_classification',
            'type': failure_type,
            'host': result._host.get_name()
        })
    
    def _send_metric(self, metric_data):
        """Send metric to observability backend"""
        import requests
        try:
            requests.post(
                'http://metrics-collector:8080/api/metrics',
                json=metric_data,
                timeout=2
            )
        except:
            pass  # Don't fail playbook over metrics collection

# Layer 3: Host-level instrumentation
---
- name: Publish deployment metrics
  hosts: all
  gather_facts: yes
  
  tasks:
    - name: Capture pre-deployment state
      block:
        - name: Get system metrics
          shell: |
            echo "cpu_usage=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}')"
            echo "memory_usage=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')"
            echo "load_average=$(uptime | awk -F'load average:' '{print $2}')"
          register: pre_metrics
          
      always:
        - name: Store pre-deployment metrics
          set_fact:
            pre_deployment_metrics: "{{ pre_metrics.stdout }}"
            
    - name: Execute deployment
      include_role:
        name: deploy_application
      register: deployment_result
      
    - name: Capture post-deployment state
      shell: |
        echo "cpu_usage=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2}')"
        echo "memory_usage=$(free | grep Mem | awk '{printf("%.1f", $3/$2 * 100.0)}')"
        echo "load_average=$(uptime | awk -F'load average:' '{print $2}')"
      register: post_metrics
      
    - name: Send comprehensive metrics
      uri:
        url: "http://prometheus-push:9091/metrics/job/ansible_deployment"
        method: POST
        body: |
          # HELP ansible_deployment_duration_seconds Deployment duration
          # TYPE ansible_deployment_duration_seconds gauge
          ansible_deployment_duration_seconds{host="{{ inventory_hostname }}"} {{ deployment_result.duration }}
          
          # Pre-deployment
          ansible_pre_deployment_cpu_usage{host="{{ inventory_hostname }}"} {{ pre_metrics.stdout | regex_search('cpu_usage=(\d+)', '\1') }}
          ansible_pre_deployment_memory_usage{host="{{ inventory_hostname }}"} {{ pre_metrics.stdout | regex_search('memory_usage=(\d+)', '\1') }}
          
          # Post-deployment
          ansible_post_deployment_cpu_usage{host="{{ inventory_hostname }}"} {{ post_metrics.stdout | regex_search('cpu_usage=(\d+)', '\1') }}
          ansible_post_deployment_memory_usage{host="{{ inventory_hostname }}"} {{ post_metrics.stdout | regex_search('memory_usage=(\d+)', '\1') }}
          
          # Status
          ansible_deployment_success{host="{{ inventory_hostname }}"} {{ "1" if deployment_result.failed == false else "0" }}
      ignore_errors: yes

# Layer 4: Centralized dashboard queries
---
# Prometheus queries to answer key questions:

# Q1: Which deployment took longer than expected?
query: |
  ansible_deployment_duration_seconds > 300
  
# Q2: Which hosts failed?
query: |
  ansible_deployment_success == 0
  
# Q3: Performance impact (CPU/memory delta)?
query: |
  (ansible_post_deployment_cpu_usage - ansible_pre_deployment_cpu_usage)
  > 20  # > 20% increase

# Q4: Failure correlation with network issues?
query: |
  increase(network_errors_total[5m]) > 0
  AND ansible_deployment_success == 0
```

---

**Document Version**: 3.0  
**Last Updated**: March 2026  
**Status**: COMPLETE - All Sections, Scenarios, and Interview Questions

---

## Hands-on Scenarios

*(Scenarios will be provided in subsequent sections)*

---

## Interview Questions

*(Interview questions will be provided in subsequent sections)*

---

**Document Version**: 1.0  
**Last Updated**: March 2026  
**Status**: Foundation Sections Complete - Subtopic Sections Pending
