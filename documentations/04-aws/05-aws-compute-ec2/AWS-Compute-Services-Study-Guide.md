# AWS Compute Services: Senior DevOps Study Guide

## Table of Contents

1. [Introduction](#introduction)
   - [Overview of Compute Services](#overview-of-compute-services)
   - [Why It Matters in Modern DevOps](#why-it-matters-in-modern-devops)
   - [Real-World Production Use Cases](#real-world-production-use-cases)
   - [Where It Appears in Cloud Architecture](#where-it-appears-in-cloud-architecture)

2. [Foundational Concepts](#foundational-concepts)
   - [Key Terminology](#key-terminology)
   - [Architecture Fundamentals](#architecture-fundamentals)
   - [Important DevOps Principles](#important-devops-principles)
   - [Best Practices](#best-practices)
   - [Common Misunderstandings](#common-misunderstandings)

3. [EC2 Lifecycle & Instance Types](#ec2-lifecycle--instance-types)
   - [Instance Lifecycle States](#instance-lifecycle-states)
   - [Instance Types & Families](#instance-types--families)
   - [Performance Characteristics](#performance-characteristics)
   - [Right-Sizing Strategies](#right-sizing-strategies)

4. [AMIs, Snapshots and Moving Instances Across Regions](#amis-snapshots-and-moving-instances-across-regions)
   - [AMI Fundamentals](#ami-fundamentals)
   - [EBS Snapshots & Lifecycle](#ebs-snapshots--lifecycle)
   - [Cross-Region Migration](#cross-region-migration)
   - [Golden Image Practices](#golden-image-practices)

5. [Encryption & Key Management](#encryption--key-management)
   - [EBS Encryption](#ebs-encryption)
   - [KMS Integration](#kms-integration)
   - [Encryption in Transit vs. At Rest](#encryption-in-transit-vs-at-rest)
   - [Key Rotation & Lifecycle](#key-rotation--lifecycle)

6. [Placement Groups](#placement-groups)
   - [Placement Group Types](#placement-group-types)
   - [Use Case Selection](#use-case-selection)
   - [Performance Optimization](#performance-optimization)
   - [Multi-AZ Considerations](#multi-az-considerations)

7. [Auto Scaling Groups & Launch Configurations](#auto-scaling-groups--launch-configurations)
   - [Launch Templates vs. Launch Configurations](#launch-templates-vs-launch-configurations)
   - [Scaling Policies & Metrics](#scaling-policies--metrics)
   - [Lifecycle Hooks](#lifecycle-hooks)
   - [Cost Optimization Through Scaling](#cost-optimization-through-scaling)

8. [Hands-On Scenarios](#hands-on-scenarios)
9. [Interview Questions](#interview-questions)

---

## Introduction

### Overview of Compute Services

AWS Compute Services represent the foundational layer of infrastructure-as-a-service offerings. EC2 (Elastic Compute Cloud) is the primary managed compute service that provides resizable virtual machine instances capable of running arbitrary workloads. For senior DevOps engineers, understanding compute services extends beyond simple instance provisioning—it encompasses architectural decisions around performance optimization, cost management, reliability, and operational efficiency at scale.

Compute services in AWS include:
- **EC2**: Virtual machines with flexible configuration options
- **Auto Scaling**: Dynamic resource scaling based on demand
- **Elastic Load Balancing**: Distribution of traffic across instances
- **Instance metadata & user data**: Configuration mechanisms during launch

### Why It Matters in Modern DevOps

Modern DevOps practices demand infrastructure that scales elastically, maintains high availability, and operates with minimal manual intervention. Compute services are fundamental because they:

1. **Enable Infrastructure as Code**: Through APIs and CloudFormation, compute infrastructure becomes versionable and reproducible
2. **Support Containerization**: EC2 instances serve as the underlying compute for ECS, EKS, and container orchestration
3. **Facilitate Automation**: Launch templates, user data scripts, and Auto Scaling enable self-healing infrastructure
4. **Provide Cost Visibility**: Pay-as-you-go model aligns infrastructure costs with actual usage
5. **Enable Multi-Region Deployments**: Portable AMIs and snapshot mechanisms support disaster recovery and geographic distribution

For DevOps engineers specifically, mastery of compute services directly impacts:
- Deployment reliability and speed
- Infrastructure cost optimization
- System observability and troubleshooting
- Disaster recovery capabilities
- Compliance and security posture

### Real-World Production Use Cases

**Case 1: E-Commerce Platform Scaling**
A high-traffic e-commerce platform requires elastic scaling during peak shopping seasons. Using Auto Scaling Groups with target tracking policies on CPU and network metrics, the infrastructure automatically scales from 10 to 500+ instances during Black Friday. Launch Templates with pre-baked AMIs ensure rapid instance provisioning in < 60 seconds. Cross-AZ deployment guarantees availability during localized outages.

**Case 2: Microservices Infrastructure**
A microservices architecture deploys 15+ services across multiple AWS accounts. Each service runs in its own ASG with independent scaling policies. Placement groups with cluster mode optimize inter-service latency for tightly-coupled components. KMS-encrypted EBS volumes ensure data at rest complies with regulatory requirements. Automated AMI building with Packer ensures consistency across all services.

**Case 3: Data Processing Pipeline**
A data processing system scales compute capacity based on job queue depth rather than CPU metrics. Spot instances mixed with On-Demand provide cost-effective scaling, while Lifecycle Hooks execute graceful shutdowns. Custom CloudWatch metrics trigger scaling to ensure optimal throughput. Snapshots capture intermediate processing states for recovery and analysis.

**Case 4: Disaster Recovery Strategy**
A critical application maintains AMIs in multiple regions for RPO/RTO compliance. Scheduled snapshots replicate to secondary regions. Dedicated hosts with specific instance types ensure capacity availability. Automated AMI freshness validation ensures DRs are current and testable.

### Where It Appears in Cloud Architecture

**Typical AWS Architecture Layers:**

```
Load Balancing Layer
    ↓
Auto Scaling Group (Compute)
    ↓
Storage Layer (EBS Volumes, Snapshots)
    ↓
Data Layer (RDS, DynamoDB, S3)
```

Compute services interact with:
- **Networking**: VPC, Security Groups, ENIs (Elastic Network Interfaces)
- **Storage**: EBS volumes, snapshots, AMIs
- **Management**: CloudWatch, Systems Manager, Cost Explorer
- **Security**: IAM roles, KMS, VPC endpoints
- **Orchestration**: Auto Scaling, Load Balancing, CloudFormation

---

## Foundational Concepts

### Key Terminology

**Instance**: An individual virtual machine running on AWS infrastructure with allocated vCPU, memory, and network resources.

**Instance Type**: A predefined configuration specifying compute, memory, storage, and networking characteristics (e.g., t3.large, m5.xlarge, c5.2xlarge).

**Instance Family**: A group of instance types optimized for specific use cases:
- **T**: Burstable general-purpose
- **M**: General-purpose, balanced compute/memory/network
- **C**: Compute-optimized, high-performance processors
- **R**: Memory-optimized, large in-memory databases
- **I**: I/O-optimized, high sequential read/write access
- **G/P**: GPU instances for graphics/machine learning
- **H/D**: High disk throughput/storage instances

**AMI (Amazon Machine Image)**: A template containing:
- Operating system (Linux, Windows, etc.)
- Pre-installed applications and libraries
- Configuration settings
- Metadata (region, architecture, permissions)

**EBS (Elastic Block Store)**: Persistent block storage volumes attached to EC2 instances, supporting snapshots and encryption.

**Snapshot**: A point-in-time backup of an EBS volume. Snapshots are incremental, storing only changed blocks.

**Launch Template**: A modern, versioned specification for launching instances (replaces Launch Configuration). Supports:
- Instance type and size
- AMI selection
- IAM roles
- Security groups
- EBS configurations
- User data scripts
- Metadata options
- Monitoring and tagging

**Auto Scaling Group (ASG)**: A logical grouping of EC2 instances with:
- Minimum, desired, and maximum capacity
- Scaling policies (simple, target tracking, step scaling)
- Health checks and replacement logic
- Lifecycle hooks for custom actions

**Placement Group**: A logical grouping affecting instance placement strategy:
- **Cluster**: Low-latency, high-bandwidth interconnect
- **Partition**: Distributed workloads with isolation between partitions
- **Spread**: Maximum availability across hardware

**User Data**: A script or cloud-init configuration executed during instance launch, enabling boot-time customization.

### Architecture Fundamentals

**EC2 Instance Lifecycle**

An EC2 instance progresses through states:

```
pending → running → stopping → stopped → (terminated)
             ↓                    ↓
          (reboot)           (restart)
             ↓                    ↓
          running            running
```

**Pending State**: The instance is being launched. Network interfaces are being configured, storage is being allocated.

**Running State**: The instance is active. The billing clock starts. Direct SSH/RDP access is available (if security groups permit).

**Stopping/Stopped**: The instance is shut down gracefully. EBS volumes are preserved, IP addresses may change. Billing is paused (except for EBS and Elastic IPs).

**Terminated**: The instance is permanently deleted. EBS volumes are deleted by default (unless DeleteOnTermination is false).

**Critical Design Insight**: For DevOps engineers, the transition from stopped to running should be incorporated into system design. Instances should be stateless, with application state stored in external services (databases, caches, object storage).

**Multi-AZ Architecture**

Availability Zones (AZs) in a region are geographically separate, fault-isolated locations:

```
Region: us-east-1
├── AZ: us-east-1a (DataCenter A)
├── AZ: us-east-1b (DataCenter B)
└── AZ: us-east-1c (DataCenter C)
```

DevOps best practice: Distribute instances across **minimum 2-3 AZs** to:
- Tolerate single AZ failure
- Enable rolling updates without service disruption
- Distribute blast radius of hardware failures

**Instance Metadata Service (IMDS)**

EC2 instances can query local metadata at `http://169.254.169.254/latest/meta-data/`:

- Instance ID, AZ, region
- Security groups, IAM role credentials
- VPC and subnet information
- Public/private IP addresses

**Critical**: IMDSv2 requires a token (session-oriented) vs. v1 (request-all-at-once). IMDSv2 protects against SSRF attacks and should be enforced in all deployments.

### Important DevOps Principles

**Infrastructure as Code (IaC)**
Compute infrastructure should be defined declaratively in CloudFormation, Terraform, or CDK. This enables:
- Version control for infrastructure changes
- Reproducible deployments across environments
- Automated testing of infrastructure before production
- Disaster recovery through infrastructure rebuild

**Immutable Infrastructure**
Instances should be treated as immutable after launch. Updates are applied by:
1. Building a new AMI with updated software
2. Updating the Launch Template version
3. Replacing ASG instances via rolling update

This principle eliminates "snowflake" servers and ensures predictable, testable deployments.

**Elasticity & Right-Sizing**
Compute capacity should dynamically adjust to demand. This requires:
- Clear scaling metrics (CPU, memory, network, application-specific metrics)
- Appropriate scaling policies with cooldown periods
- Regular review of actual vs. provisioned capacity
- Use of multiple instance types in a single ASG for flexibility

**High Availability Design**
Single points of failure must be eliminated:
- No single-instance deployments in production
- Minimum 2-3 instances per service across AZs
- Load balancers distributing traffic based on health checks
- Automated instance replacement on failure

**Security by Default**
- IAM roles instead of credentials on instances
- Encrypted EBS volumes for sensitive data
- Minimal security group rules (least privilege)
- Regular AMI patching and vulnerability scanning
- Encrypted snapshots for sensitive backups

### Best Practices

**1. AMI Management**
- **Automate AMI building**: Use Packer to build consistent, versioned AMIs
- **Minimal base images**: Start from official AWS AMIs, customize only what's necessary
- **Regular patching**: Rebuild AMIs monthly or when critical patches are available
- **Version tracking**: Tag AMIs with explicit versions and application versions
- **Snapshot testing**: Test new AMIs in non-production before production rollout

**2. Launch Template Strategy**
- **Version all templates**: Use Launch Template versions for gradual rollouts
- **LatestVersionNumber vs. specific versions**: For ASGs, pin to specific versions during controlled deployments
- **IMDSv2 enforcement**: Set token requirement to required (HTTP PUT-based tokens)
- **Monitoring defaults**: Enable detailed CloudWatch monitoring in templates
- **Separate concerns**: Create separate templates for different workload types

**3. Auto Scaling Configuration**
- **Meaningful scaling metrics**: Use target tracking policies on relevant metrics (not just CPU)
- **Scale-out faster than scale-in**: Aggressive scale-out prevents service degradation; conservative scale-in saves costs
- **Lifecycle hooks for graceful shutdown**: Allow in-flight requests to complete before termination
- **Cooldown periods**: Prevent thrashing with appropriate cooldown (default 300 seconds often needs adjustment)
- **Regular testing**: Run chaos engineering tests to verify scaling behavior

**4. Right-Sizing**
- **Analyze utilization**: Use CloudWatch metrics and AWS Compute Optimizer
- **Consider burstable instances**: T3/T4 instances for variable workloads (development, web tier)
- **Spot instances**: Use for non-critical, fault-tolerant workloads (30-90% savings)
- **Reserved Instances/Savings Plans**: For stable, predictable workloads (30-40% savings)

**5. Monitoring & Observability**
- **CloudWatch metrics**: Monitor CPU, network I/O, disk I/O, status checks
- **Application metrics**: Push custom metrics for meaningful scaling insights
- **Logs aggregation**: Centralize logs (CloudWatch, ELK, Splunk) for troubleshooting
- **Status checks**: Distinguish between system status checks (AWS infrastructure) and instance status checks (OS-level)

### Common Misunderstandings

**Misunderstanding #1: Stopped Instances = Zero Cost**
**Reality**: Stopped instances don't incur compute charges, but elastic IPs and EBS storage continue to be billed. A stopped instance for disaster recovery costs ~10-15% of a running instance.

**Corrective Practice**: Calculate total cost of ownership including storage, network, and IP allocations.

**Misunderstanding #2: ASGs Always Have Even Distribution**
**Reality**: ASGs distribute new instances across AZs, but may become imbalanced over time due to:
- Manual instance terminations in specific AZs
- Capacity constraints in specific AZs
- Diverse instance types with different availability

**Corrective Practice**: Use ASG rebalancing (manual refresh, instance warm-up) and monitor AZ distribution via CloudWatch.

**Misunderstanding #3: CPU Metrics Alone Indicate Scaling Needs**
**Reality**: CPU doesn't capture:
- Memory pressure (swap usage, OOM kills)
- Network saturation
- I/O wait times
- Application queue depth

**Corrective Practice**: Implement application-level metrics (queue depth, request latency, error rates) for scaling decisions.

**Misunderstanding #4: Snapshots Are Backups**
**Reality**: Snapshots are point-in-time copies of block data, not true backups. They're vulnerable to:
- Account compromise (entire snapshot deleted)
- Regional disasters (snapshots in same region as volume)
- Accidental deletion during cleanup

**Corrective Practice**: Implement 3-2-1 backup strategy (3 copies, 2 media types, 1 off-site), with snapshots for operational use and separate backups for compliance.

**Misunderstanding #5: AMIs Are Region-Portable**
**Reality**: AMIs are region-specific and must be copied to target regions before use. This involves:
- Re-encrypting with target region KMS keys
- Potential divergence during regional copies
- Bandwidth costs for cross-region transfers

**Corrective Practice**: Maintain a CI/CD pipeline that builds AMIs in all required regions simultaneously, or uses a primary region with documented copy procedures.

---

## EC2 Lifecycle & Instance Types

### Textual Deep Dive

#### Internal Working Mechanism

The EC2 instance lifecycle consists of several states that define the operational status of a virtual machine:

1. **Pending** - Instance is being launched (typically 1-2 seconds)
2. **Running** - Instance is active and can accept connections
3. **Stopping** - Instance is being shut down gracefully
4. **Stopped** - Instance is powered off but retained with persistent storage
5. **Terminated** - Instance is permanently deleted
6. **Rebooting** - Instance is restarting (internal only, not visible as separate state)

The EC2 hypervisor (Xen or KVM) virtualizes the underlying hardware by:
- Allocating vCPU cores from a physical CPU pool with CPU credits for burstable types
- Mapping virtual block devices to underlying EBS volumes or instance store
- Assigning ENI (Elastic Network Interface) with associated IP addresses
- Isolating memory allocation between instances
- Managing I/O operations with QoS (Quality of Service) limits

**Instance types** are grouped into families optimized for different workloads:

- **General Purpose (t3, m5, m6)**: Balanced CPU, memory, network (web servers, small databases)
- **Compute Optimized (c5, c6)**: High CPU-to-memory ratio (batch processing, HPC)
- **Memory Optimized (r5, r6, x2)**: High memory (large in-memory databases, cache servers)
- **Storage Optimized (i3, h1, d2)**: High sequential I/O throughput (NoSQL, data warehousing)
- **GPU/ML Optimized (p3, g4)**: GPUs for ML training and graphics rendering
- **Accelerated Computing (f1)**: FPGAs for specialized workloads

#### Architecture Role

In AWS architecture, EC2 serves as:
- **Compute foundation** for application workloads
- **Control plane** for managing infrastructure
- **Data processing node** in distributed systems
- **Jump host** for system administration

The lifecycle directly impacts:
- **Cost optimization** (stopped vs. terminated instances)
- **Disaster recovery** (ability to restart without data loss)
- **Scheduling** (automated startup/shutdown via EventBridge + Lambda)

#### Production Usage Patterns

1. **High Availability Pattern**
   - Multi-AZ deployment with ALB/NLB
   - Auto Scaling Groups with mixed instance types
   - Graceful shutdown handling with connection draining

2. **Cost Optimization**
   - Spot Instances for non-critical workloads (70% cost savings)
   - Reserved Instances for baseline capacity
   - Scheduled scaling for predictable traffic patterns

3. **Blue-Green Deployments**
   - Launch new instances in "green" environment
   - Switch traffic via load balancer
   - Keep old instances ("blue") for quick rollback

#### DevOps Best Practices

1. **Infrastructure as Code**
   - Define instances in Terraform or CloudFormation
   - Version control all infrastructure changes
   - Use consistent naming conventions

2. **Monitoring & Observability**
   - CloudWatch metrics: CPU, network I/O, disk I/O
   - Systems Manager Agent for detailed OS-level metrics
   - X-Ray for application tracing
   - Custom metrics for application-specific KPIs

3. **Security Hardening**
   - Use IMDSv2 (Instance Metadata Service v2) to prevent SSRF
   - Encrypt EBS volumes by default
   - Use security groups with principle of least privilege
   - Implement OS-level hardening (SELinux, AppArmor)

4. **Capacity Planning**
   - Monitor metrics over 30+ days to identify trends
   - Right-size instances to actual usage patterns
   - Use CloudWatch Insights for cost analysis queries

#### Common Pitfalls

1. **Instance Store Ephemeral Data Loss**
   - Data on instance store is lost when instance stops/terminates
   - Must use EBS for persistent storage

2. **Licensing Compliance**
   - Windows licenses tied to instances require proper tracking
   - Dedicated Hosts might be necessary for license portability

3. **AMI Permissions Issues**
   - Launching instances with private/inaccessible AMIs
   - Forgetting to share AMIs across accounts

4. **Network Configuration**
   - Wrong security group causing connectivity issues
   - Incorrect subnet causing no internet connectivity
   - Missing IAM role causing credential issues

5. **Credit Balance Exhaustion (Burstable Types)**
   - t2/t3 instances lose performance when CPU credits exhausted
   - Should monitor CPUCreditBalance metric

### Practical Code Examples

#### AWS CLI Commands

```bash
# Launch an instance
aws ec2 run-instances \
  --image-id ami-0c55b159cbfafe1f0 \
  --instance-type t3.medium \
  --key-name my-keypair \
  --security-group-ids sg-12345678 \
  --subnet-id subnet-12345678 \
  --iam-instance-profile Name=EC2-SSM-Role \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=web-server-1}]' \
  --monitoring Enabled=true

# Get instance details
aws ec2 describe-instances \
  --instance-ids i-1234567890abcdef0 \
  --query 'Reservations[0].Instances[0].[InstanceId,State.Name,InstanceType,PrivateIpAddress]' \
  --output table

# Stop an instance (preserves EBS volumes)
aws ec2 stop-instances --instance-ids i-1234567890abcdef0

# Terminate an instance (deletes root volume if DeleteOnTermination=true)
aws ec2 terminate-instances --instance-ids i-1234567890abcdef0

# Modify instance type (requires stop)
aws ec2 modify-instance-attribute \
  --instance-id i-1234567890abcdef0 \
  --instance-type "{\"Value\": \"t3.large\"}"

# Monitor CPU credit balance
aws cloudwatch get-metric-statistics \
  --namespace AWS/EC2 \
  --metric-name CPUCreditBalance \
  --dimensions Name=InstanceId,Value=i-1234567890abcdef0 \
  --statistics Average \
  --start-time 2026-03-01T00:00:00Z \
  --end-time 2026-03-07T00:00:00Z \
  --period 3600
```

#### CloudFormation Template

```yaml
AWSTemplateFormatVersion: '2010-09-09'
Description: 'EC2 Instance in Production VPC with Monitoring'

Parameters:
  InstanceType:
    Type: String
    Default: t3.medium
    AllowedValues:
      - t3.small
      - t3.medium
      - t3.large
      - m5.large
      - m5.xlarge

Resources:
  # IAM Role for EC2
  EC2Role:
    Type: AWS::IAM::Role
    Properties:
      AssumeRolePolicyDocument:
        Version: '2012-10-17'
        Statement:
          - Effect: Allow
            Principal:
              Service: ec2.amazonaws.com
            Action: sts:AssumeRole
      ManagedPolicyArns:
        - arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore
        - arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy

  EC2InstanceProfile:
    Type: AWS::IAM::InstanceProfile
    Properties:
      Roles:
        - !Ref EC2Role

  # Security Group
  EC2SecurityGroup:
    Type: AWS::EC2::SecurityGroup
    Properties:
      GroupDescription: Security group for web server
      VpcId: vpc-12345678
      SecurityGroupIngress:
        - IpProtocol: tcp
          FromPort: 80
          ToPort: 80
          CidrIp: 0.0.0.0/0
        - IpProtocol: tcp
          FromPort: 443
          ToPort: 443
          CidrIp: 0.0.0.0/0
      SecurityGroupEgress:
        - IpProtocol: -1
          CidrIp: 0.0.0.0/0
      Tags:
        - Key: Name
          Value: web-server-sg

  # EC2 Instance
  WebServerInstance:
    Type: AWS::EC2::Instance
    Properties:
      ImageId: ami-0c55b159cbfafe1f0  # Amazon Linux 2
      InstanceType: !Ref InstanceType
      IamInstanceProfile: !Ref EC2InstanceProfile
      SecurityGroupIds:
        - !Ref EC2SecurityGroup
      SubnetId: subnet-12345678
      Monitoring: true
      MetadataOptions:
        HttpTokens: required  # IMDSv2 enforcement
        HttpPutResponseHopLimit: 1
      UserData:
        Fn::Base64: |
          #!/bin/bash
          yum update -y
          yum install -y httpd
          systemctl start httpd
          systemctl enable httpd
          echo "<h1>Hello from $(hostname)</h1>" > /var/www/html/index.html
      Tags:
        - Key: Name
          Value: web-server
        - Key: Environment
          Value: production

  # CloudWatch Alarm for High CPU
  HighCPUAlarm:
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: WebServer-HighCPU
      MetricName: CPUUtilization
      Namespace: AWS/EC2
      Statistic: Average
      Period: 300
      EvaluationPeriods: 2
      Threshold: 80
      ComparisonOperator: GreaterThanThreshold
      Dimensions:
        - Name: InstanceId
          Value: !Ref WebServerInstance
      AlarmActions:
        - arn:aws:sns:us-east-1:123456789012:alerts

Outputs:
  InstanceId:
    Value: !Ref WebServerInstance
    Description: Instance ID of the web server
  PublicIP:
    Value: !GetAtt WebServerInstance.PublicIp
    Description: Public IP address of the instance
  PrivateIP:
    Value: !GetAtt WebServerInstance.PrivateIp
    Description: Private IP address of the instance
```

### ASCII Diagrams: EC2 Instance Lifecycle State Machine

```
                    ┌─────────────────────────────────────────┐
                    │                                         │
                    ▼                                         │
         ┌──────────────┐        aws ec2         ┌─────────────┴──┐
         │   pending    │◄─────run-instances─────┤   terminated   │
         └──────┬───────┘                        │  (Permanent)   │
                │                                └────────────────┘
                │ (1-2 seconds)                          ▲
                │                                        │
                ▼                    terminate-instances │
    ┌──────────────────┐  ─────────────────────────────►│
    │     running      │                                 │
    │  (Operational)   │                                 │
    └──────┬───────────┘                                 │
           │      ▲                                       │
           │      │                                       │
      stop │      │ start                                │
           │      │                                       │
           ▼      └───────────┐                          │
    ┌──────────────┐    ┌──────────────┐                │
    │   stopping   │    │   starting   │                │
    └──────┬───────┘    └──────┬───────┘                │
           │                   │                         │
           │                   │ (Data persisted         │
           ▼                   ▼  on EBS)               │
    ┌──────────────┐    ┌──────────────────────────────┘
    │   stopped    │    │
    │(Preserved)   │    │
    └──────────────┘    │
                        │
            reboot-instances──┐
                              │
            ┌─────────────────┘
            │ (Implicit start)
            ▼
```

---

## Instance Types & Families

### Deep Dive: Instance Type Selection
| State persistence | EBS volumes retained | DeleteOnTermination applies |
| Billing | EBS only (compute free) | None |
| Recovery | Can be restarted | Permanent deletion |
| Elastic IP | Retained (if associated) | Released |
| Data loss risk | Low | Complete |



**Deep Dive: Instance Type Selection**

**General Purpose (M-family)**
- **Use case**: Web servers, enterprise applications, development environments
- **Characteristics**: Balanced CPU:RAM:Network (1vCPU : ~3.75GB RAM)
- **Subtypes**:
  - **M6i/M7i**: Latest generation, Intel 3rd-gen Xeon, ideal for right-sizing
  - **M5.large ($0.096/hr)**: Cost-effective for standard workloads
  - **M5.4xlarge ($1.536/hr)**: Higher throughput, testing large datasets

**When to choose**: Default choice unless specific optimizations needed. Start with M-type and scale horizontally rather than vertically.

**Compute Optimized (C-family)**
- **Use case**: Batch processing, video encoding, high-performance computing, mathematical simulations
- **Characteristics**: High CPU:RAM ratio (1vCPU : ~2GB RAM), superior processor speed
- **Subtypes**:
  - **C6i**: Intel 3rd-gen Xeon, latest general compute
  - **C5**: Cost-effective compute optimization (slightly older architecture)
  - **C5.2xlarge ($0.34/hr)**: 8vCPU, ideal for encoding pipelines

**When to choose**: When CPU time dominates workload cost. Monitor: CPU utilization > 70%, memory utilization < 40%.

**Memory Optimized (R-family, X-family)**
- **Use case**: In-memory databases (Redis, Memcached), SAP HANA, data warehousing
- **Characteristics**: High CPU:RAM ratio (1vCPU : 8GB RAM or higher)
- **Subtypes**:
  - **R6i/R7i**: Latest, Intel-based, in-memory applications
  - **X2idn**: Ultra-high memory (1:48 vCPU:RAM), lowest latency NVMe
  - **r5.4xlarge ($1.008/hr)**: 16vCPU, 128GB RAM for Elasticsearch, large Redis instances

**When to choose**: When application loads dataset into memory. Monitor: Memory utilization > 80%, CPU < 50%.

**Storage Optimized (I-family, D-family, H-family)**
- **Use case**: NoSQL databases (Cassandra, DynamoDB), data warehousing (Redshift), distributed file systems
- **Characteristics**: High IOPS and throughput, NVMe SSD storage
- **Subtypes**:
  - **i3/i4i**: NVMe SSD, ultra-high random IOPS
  - **d2**: Dense HDD, sequential throughput focused
  - **h1**: High disk throughput + sequential I/O

**When to choose**: When disk I/O is bottleneck. Storage-to-CPU: i-type = SSD (IOPS), d-type = HDD (throughput).

**Burstable Performance (T-family)**
- **Use case**: Dev/test, low-traffic web applications, baseline + occasional spikes
- **Characteristics**: Accumulates "CPU credits" during light use, bursts when needed
- **Credit system**: 
  - t3.micro: 6 credits/hour baseline
  - t3.small: 12 credits/hour baseline
  - t3.medium: 24 credits/hour baseline
  - 1 vCPU for 1 hour = 60 credits

**When to choose**: Development, staging, non-critical applications. Monitor: CPU credit balance doesn't consistently decrease (indicates sustained high CPU).

**Accelerated Computing (P, G, F families)**
- **GPU instances** (P, G): Machine learning, graphics rendering, video transcoding
- **FPGA instances** (F): Hardware acceleration, bit-stream programming
- **Pricing**: $2-10/hour depending on GPU type (K80, T4, V100, A100)

**When to choose**: Only when GPU acceleration provides > 3x speedup compared to CPU-optimized instances.

#### Instance Type Naming Convention
```
m     5        .large        optimized
↓     ↓         ↓            ↓
Family Generation Size    Metal flag
```

- **Generation**: 5, 6i (Intel), 6a (AMD), 7i (latest)
- **Size progression**: nano < micro < small < medium < large < xlarge < 2xlarge < 4xlarge < 9xlarge < 12xlarge < 24xlarge

### Performance Characteristics

**vCPU Architecture**
- **Physical core vs. vCPU**: Each physical core = 2 vCPUs (due to hyper-threading)
- **T-family exception**: T-family vCPUs are based on fractional allocation (not hyperthreaded)
- **Processor specifications**: Available at https://docs.aws.amazon.com/ec2/latest/instancetypes/ (frequency, cache, TDP)

**Memory Bandwidth**
- **M/C-families**: ~5 GB/s per instance
- **R-families**: ~7 GB/s per instance
- **I-families**: ~25+ GB/s per instance

**Network Performance**
- **Up to 25 Gbps**: x1e, c5, r5, m5 (large sizes)
- **Up to 100 Gbps**: Latest generation (c6i, r6i, m6i) with enhanced networking

**Enhanced Networking Options**:
- **ENA** (Elastic Network Adapter): Up to 100 Gbps, 30µs latency
- **Intel 82599 VF**: Up to 10 Gbps
- Required: Placement in VPC, compatible AMI, EBS optimization

### Right-Sizing Strategies

**1. Measuring Instance Utilization**

CloudWatch metrics to monitor (5-minute granularity recommended):
```
CPUUtilization (avg, peak)
NetworkIn / NetworkOut (bytes)
EBSReadBytes / EBSWriteBytes (I/O throughput)
DiskReadOps / DiskWriteOps (IOPS)
```

**Utilization Profiling**:
- **Low CPU (<20%), Low Memory (<25%)**: Downsize immediately
- **Medium CPU (30-60%), High Memory (80%+)**: Memory-optimized instance
- **High CPU (>80%), Low Memory (<50%)**: Compute-optimized instance
- **Inconsistent spikes**: Burstable (T-family) or scheduled scaling

**2. AWS Compute Optimizer**

Automated right-sizing recommendation engine:
- Analyzes 14+ days of CloudWatch metrics
- Recommends instance types with similar or better performance
- Estimates monthly savings
- Patterns for memory, CPU, network utilization

**Integration**: 
```
CloudFormation → Update Launch Template → ASG instance refresh
```

**3. Horizontal vs. Vertical Scaling**

**Horizontal Scaling** (Preferred in DevOps):
- Distribute load across multiple smaller instances
- Enables auto-scaling without manual intervention
- Provides fault isolation (failure affects subset of traffic)
- Cost optimization via mix of instance types

**Vertical Scaling** (Limited use cases):
- Increase instance size for single service
- Requires downtime (stop instance → change type → start)
- Hits physical limits (no instance type larger than 24xlarge)
- Useful for: databases, caches (if single-instance design required)

**Mixed Strategy**:
```
ASG with:
- 3-5 small instances (normal load)
- 1 medium instance (burst capacity)
- Dynamic metric-based scaling
```

---

## AMIs, Snapshots and Moving Instances Across Regions

### AMI Fundamentals

**AMI Composition**

An AMI consists of:
1. **Root device template**: Configuration for root volume
   - Volume type (gp3, io2, etc.)
   - Size (minimum 8 GB for most Linux)
   - Encryption status
   - DeleteOnTermination flag

2. **Block device mappings**: Configuration for additional EBS volumes
3. **Permissions**: Who can launch instances from this AMI
4. **Virtualization type**: HVM (hardware virtual machine) or Paravirtual (deprecated)
5. **Architecture**: x86_64, arm64 (Graviton2)
6. **Metadata**: Region, creation time, description, tags

**Official AWS AMIs**
- **Amazon Linux 2**: AWS-optimized, frequent patches, low cost
- **Amazon Linux 2023**: Long-term support, more frequent updates
- **Ubuntu**: Canonical-maintained, broad software ecosystem
- **RHEL**: RedHat Enterprise Linux, commercial support available
- **Windows**: Multiple versions (2019, 2022, 2025), high licensing costs

**Custom AMI Creation**

**Method 1: Packer Automation** (Recommended)
```json
{
  "builders": [{
    "type": "amazon-ebs",
    "region": "us-east-1",
    "source_ami": "ami-0c2b8ca1fac6ddb2",
    "instance_type": "t3.micro",
    "ami_name": "myapp-{{timestamp}}"
  }],
  "provisioners": [{
    "type": "shell",
    "inline": ["apt-get update", "apt-get install -y nodejs"]
  }]
}
```

**Advantages**:
- Code-driven reproducibility
- Version control integration
- Multi-region simultaneous builds
- Automated testing in build pipeline

**Method 2: AWS Systems Manager Image Builder**
- GUI-based, no code required
- Automated scanning for CVEs
- Scheduled builds via cron
- Output to multiple regions

**Method 3: Manual from Running Instance**
1. Launch instance from base AMI
2. Connect and configure (install software, copy configs)
3. Run: `aws ec2 create-image --instance-id i-1234567890abcdef0 --name "custom-ami-name"`
4. Wait for snapshot of root volume
5. Resulting AMI is ready for launching

**Practice Difference**:
- Manual: Acceptable for one-off testing, not production
- Packer: Standard for production infrastructure

**AMI Permissions**

**Default**: AMI is accessible only by AWS account that created it.

**Sharing Options**:
```bash
# Explicit account sharing
aws ec2 modify-image-attribute \
  --image-id ami-0123456789 \
  --launch-permission "Add=[{UserId=123456789012}]"

# Public sharing (not recommended for security-sensitive AMIs)
aws ec2 modify-image-attribute \
  --image-id ami-0123456789 \
  --launch-permission "Add=[{Group=all}]"
```

**Security Practice**: Don't share AMIs publicly; instead, publish to Amazon ECR and use container-based deployment where possible.

### EBS Snapshots & Lifecycle

**Snapshot Mechanics**

Snapshots are incremental backups of EBS volumes:

1. **Initial snapshot**:
   - Copies all blocks from volume
   - Stored in S3 (customer-hidden)
   - Requires volume to be attached (doesn't need to be running)

2. **Incremental snapshots**:
   - Only changed blocks since last snapshot
   - ~5-30% size of full snapshot (typical workload)
   - Faster backup window
   - **Critical**: Must maintain full snapshot chain; can't delete intermediate snapshots

3. **Snapshot recovery**:
   - Create volume from snapshot in target AZ
   - Data populated on first read (slight latency)
   - Or fast restore option for latency-sensitive use

**Encryption Snapshots**

```bash
# Create encrypted volume
aws ec2 create-volume \
  --size 100 \
  --availability-zone us-east-1a \
  --encrypted \
  --kms-key-id arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012

# Snapshot automatically inherits encryption from source volume

# Copy snapshot with KMS re-encryption
aws ec2 copy-snapshot \
  --source-region us-east-1 \
  --source-snapshot-id snap-1234567890abcdef0 \
  --destination-region us-west-2 \
  --description "Encrypted snapshot copy" \
  --encrypted \
  --kms-key-id arn:aws:kms:us-west-2:123456789012:key/...
```

**Snapshot Lifecycle Management**

**Automated via DLM (Data Lifecycle Manager)**:
```
Policy:
├── Resource type: VOLUME
├── Tags to target: "Backup=Daily"
├── Schedule:
│   ├── Frequency: Every 24 hours
│   ├── Time: 03:00 UTC
│   └── Interval: Create every day
├── Retention:
│   ├── Count: 30 (keep 30 most recent)
│   └── Age: 30 days
└── Cross-region copy:
    ├── Target region: us-west-2
    └── Retention: 14 days
```

**Manual lifecycle**:
```bash
# List snapshots older than 30 days
aws ec2 describe-snapshots \
  --filters "Name=start-time,Values=2023-01-01T00:00:00Z" \
  --query 'Snapshots[*].[SnapshotId,StartTime,VolumeSize]'

# Delete old snapshots
aws ec2 delete-snapshot --snapshot-id snap-1234567890abcdef0
```

**Cost Optimization**:
- EBS snapshot storage: ~$0.05/GB-month
- 100GB snapshot for 1 month = $5
- **Strategy**: Keep 7 daily snapshots (1-week retention), 4 weekly (1-month retention), 12 monthly (1-year retention)

### Cross-Region Migration

**Scenario**: Move application from us-east-1 to eu-west-1 for compliance or disaster recovery.

**Component-wise Migration**:

**1. AMI Migration**
```bash
# Copy AMI from source to destination region
aws ec2 describe-images \
  --image-ids ami-12345678 \
  --region us-east-1

# Copy with re-encryption in destination KMS
aws ec2 copy-image \
  --source-region us-east-1 \
  --source-image-id ami-12345678 \
  --destination-region eu-west-1 \
  --name "myapp-eu" \
  --description "Application migrated to EU" \
  --encrypted \
  --kms-key-id arn:aws:kms:eu-west-1:123456789012:key/...
```

**2. EBS Volume Migration**
```bash
# Source: us-east-1a, Volume: vol-12345678
# Step 1: Create snapshot in source region
aws ec2 create-snapshot \
  --volume-id vol-12345678 \
  --description "Migration snapshot"

# Step 2: Wait for completion
aws ec2 wait snapshot-completed --snapshot-ids snap-12345678

# Step 3: Copy to destination region
aws ec2 copy-snapshot \
  --source-region us-east-1 \
  --source-snapshot-id snap-12345678 \
  --destination-region eu-west-1

# Step 4: Create volume in destination region
aws ec2 create-volume \
  --snapshot-id snap-destination-id \
  --availability-zone eu-west-1a \
  --volume-type gp3
```

**3. Instance Migration (Combined Approach)**

```bash
# Update Launch Template to use destination region
aws ec2 create-launch-template-version \
  --launch-template-id lt-12345678 \
  --source-version 1 \
  --launch-template-data \
  '{
    "ImageId": "ami-eu-west-id",
    "BlockDeviceMappings": [
      {
        "DeviceName": "/dev/xvda",
        "Ebs": {
          "SnapshotId": "snap-eu-snapshot-id",
          "VolumeSize": 100,
          "VolumeType": "gp3"
        }
      }
    ]
  }'

# Create ASG in destination region with new template
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name myapp-eu \
  --launch-template LaunchTemplateId=lt-12345678,Version='$Latest' \
  --min-size 2 \
  --max-size 10 \
  --desired-capacity 2 \
  --availability-zones eu-west-1a eu-west-1b eu-west-1c
```

**Parallel Migration for Zero-Downtime**

```
Time     us-east-1 (Primary)          eu-west-1 (Secondary)
T0       100% traffic
         ↓
T1       90% traffic         ← Route53 gradual shift → 10% traffic
         ↓                                              ↓
T2       50% traffic         ← All traffic healthy → 50% traffic
         ↓                                              ↓
T3       Decommission        ← Validation complete → 100% traffic
```

### Golden Image Practices

**Golden Image**: Production-ready, hardened, tested AMI used as baseline for all deployments.

**Characteristics of a Golden Image**:
1. **Minimal base**: Start from official vendor AMI, add only necessary packages
2. **Security hardened**: CIS benchmarks, security patches, SSH hardening
3. **Monitoring enabled**: CloudWatch agent, Systems Manager agent pre-installed
4. **Pre-configured networking**: Correct hostname, DNS settings, NTP
5. **Application framework**: Runtime (Java, Node, Python, .NET), package managers
6. **Versioned**: Explicit version number, tracked in version control

**Building a Golden Image (Packer Example)**

```hcl
source "amazon-ebs" "ubuntu" {
  ami_name      = "golden-ubuntu-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"
  instance_type = "t3.micro"
  region        = "us-east-1"
  source_ami    = "ami-0c2b8ca1fac6ddb2"  # Ubuntu 22.04 LTS
  
  tags = {
    Name           = "golden-image"
    Version        = var.version
    BuildDate      = timestamp()
    SecurityPatch  = "2025-03-06"
  }
}

build {
  sources = ["source.amazon-ebs.ubuntu"]

  # System updates
  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get upgrade -y",
      "apt-get install -y curl wget vim net-tools"
    ]
  }

  # Security hardening
  provisioner "shell" {
    script = "${path.root}/scripts/hardening.sh"
  }

  # CloudWatch agent installation
  provisioner "shell" {
    inline = [
      "wget https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb",
      "dpkg -i -E ./amazon-cloudwatch-agent.deb"
    ]
  }

  # SSM agent installation (Ubuntu pre-installed in recent versions)
  provisioner "shell" {
    inline = [
      "snap install amazon-ssm-agent --classic",
      "snap start amazon-ssm-agent"
    ]
  }

  # Application runtime (Node.js example)
  provisioner "shell" {
    inline = [
      "curl -fsSL https://deb.nodesource.com/setup_18.x | bash -",
      "apt-get install -y nodejs"
    ]
  }

  # Final validation
  provisioner "shell" {
    inline = [
      "node --version",
      "npm --version",
      "aws --version"
    ]
  }
}

variable "version" {
  type = string
  default = "1.0.0"
}
```

**Golden Image Maintenance**

**Monthly Refresh Cycle**:
1. Build new golden image with latest patches
2. Test in non-production (UAT, staging)
3. Document changes in release notes
4. Tag as production-ready
5. Update Launch Template to reference new image version
6. Perform canary deployment (5% of fleet)
7. Monitor metrics for 24 hours
8. If stable, roll out to entire fleet via ASG instance refresh

**Image Validation**

```bash
# Launch test instance from golden image
aws ec2 run-instances \
  --image-id ami-golden-12345 \
  --instance-type t3.micro \
  --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=golden-test}]'

# Run validation tests
ssh -i keypair.pem ec2-user@instance-ip
  # Verify software versions
  java -version
  docker --version
  aws --version
  
  # Verify security settings
  sudo auditctl -l
  sudo systemctl status fail2ban
  
  # Verify monitoring
  ps aux | grep cloudwatch
  ps aux | grep ssm
```

---

## Encryption & Key Management

### EBS Encryption

**Encryption at Rest Mechanics**

EBS volumes support AES-256 encryption:

1. **Encryption scope**: 
   - Data blocks on physical media
   - Data in transit between instance and storage
   - **NOT** snapshots created from encrypted volumes (unless explicitly encrypted during copy)

2. **Performance impact**: Negligible
   - Modern EBS optimized instances: < 1% CPU overhead
   - IOPS/throughput: No reduction
   - Latency: Transparent to application

3. **Key management**: 
   - AWS-managed keys (default): AWS manages encryption completely
   - Customer-managed keys (CMK): Customer controls key lifecycle, rotation, permissions

**Enabling Encryption**

```bash
# Option 1: Encrypt at volume creation
aws ec2 create-volume \
  --size 100 \
  --availability-zone us-east-1a \
  --volume-type gp3 \
  --encrypted \
  --kms-key-id arn:aws:kms:us-east-1:123456789012:key/12345678-abcd-1234-abcd-123456789012

# Option 2: Encrypt existing volume (requires downtime)
# Step 1: Create snapshot
aws ec2 create-snapshot --volume-id vol-12345678

# Step 2: Create encrypted volume from snapshot
aws ec2 create-volume \
  --snapshot-id snap-12345678 \
  --availability-zone us-east-1a \
  --encrypted \
  --kms-key-id <CMK ARN>

# Step 3: Stop instance, detach volume, attach new volume, start
aws ec2 stop-instances --instance-ids i-12345678
aws ec2 detach-volume --volume-id vol-12345678
aws ec2 attach-volume \
  --volume-id vol-encrypted-new \
  --instance-id i-12345678 \
  --device /dev/sdf

# Option 3: Enable by default for region (AWS account level)
aws ec2 enable-ebs-encryption-by-default
```

**Encryption During AMI Copy**

```bash
# Copy unencrypted AMI with encryption
aws ec2 copy-image \
  --source-region us-east-1 \
  --source-image-id ami-12345678 \
  --destination-region us-west-2 \
  --name "myapp-encrypted" \
  --encrypted \
  --kms-key-id arn:aws:kms:us-west-2:123456789012:key/...

# Note: Volume root device mapping must also specify encryption
aws ec2 create-launch-template \
  --launch-template-name "encrypted-template" \
  --launch-template-data '{
    "ImageId": "ami-encrypted-12345",
    "BlockDeviceMappings": [
      {
        "DeviceName": "/dev/xvda",
        "Ebs": {
          "VolumeSize": 100,
          "VolumeType": "gp3",
          "Encrypted": true,
          "KmsKeyId": "arn:aws:kms:us-east-1:123456789012:key/..."
        }
      }
    ]
  }'
```

### KMS Integration

**Understanding KMS Hierarchy**

```
AWS Account
├── KMS Service
    ├── CMK (Customer Master Key) - Permission boundary
    │   ├── Key Policy - IAM-like policy for key usage
    │   ├── Grants - Time-bound delegated access
    │   └── Audit - CloudTrail logs all operations
    └── Data Keys
        ├── Plaintext data key (returned to application)
        └── Encrypted data key (stored with encrypted data)
```

**Managing CMK for EBS**

```bash
# Step 1: Create CMK with management permissions
aws kms create-key \
  --description "EBS encryption key for production" \
  --key-usage ENCRYPT_DECRYPT \
  --origin AWS_KMS \
  --multi-region FALSE

# Step 2: Create alias for easy reference
aws kms create-alias \
  --alias-name alias/ebs-prod-key \
  --target-key-id 12345678-abcd-1234-abcd-123456789012

# Step 3: Set key policy to allow EC2 and EBS services
aws kms put-key-policy \
  --key-id arn:aws:kms:us-east-1:123456789012:key/12345678-abcd-1234-abcd-123456789012 \
  --policy-name default \
  --policy file://key-policy.json
```

**Key Policy for EBS** (key-policy.json):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "Enable IAM Root Permissions",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:root"
      },
      "Action": "kms:*",
      "Resource": "*"
    },
    {
      "Sid": "Allow EC2 Service",
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey",
        "kms:CreateGrant"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow EBS Service",
      "Effect": "Allow",
      "Principal": {
        "Service": "ebs.amazonaws.com"
      },
      "Action": [
        "kms:Decrypt",
        "kms:GenerateDataKey",
        "kms:DescribeKey",
        "kms:CreateGrant"
      ],
      "Resource": "*"
    },
    {
      "Sid": "Allow EC2 Instances to Decrypt",
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::123456789012:role/EC2-Instance-Role"
      },
      "Action": [
        "kms:Decrypt",
        "kms:DescribeKey"
      ],
      "Resource": "*",
      "Condition": {
        "StringEquals": {
          "kms:ViaService": "ec2.us-east-1.amazonaws.com"
        }
      }
    }
  ]
}
```

**Key Parameter Explanation**:
- **Principal**: Who can use the key (AWS account, IAM role, service principal)
- **Action**: Which KMS operations are allowed
- **Resource**: Which keys the policy applies to
- **Condition**: Additional restrictions (source service, IP, VPC, account)

### Encryption in Transit vs. At Rest

**At Rest Encryption**

**Scope**: Data stored on physical EBS disks

**Implementation**:
```bash
# EBS volumes
- Volume creation with --encrypted flag
- Default KMS key (AWS-managed) or CMK

# Snapshots
- Snapshot of encrypted volume inherits encryption
- Snapshot copy requires explicit re-encryption with destination KMS key
```

**Security Model**:
```
Application → Instance → EBS Encryption Module → Encrypted Volume
             (Plaintext)  (AES-256 encryption)    (Ciphertext)
```

**In Transit Encryption**

**Scope**: Data moving between instance and storage

**AWS Implementation**:
- Automatic via TLS
- Transparent to EC2 instance (application sees plaintext)
- No performance penalty
- Prevents network eavesdropping

**Additional In-Transit Encryption**(for security beyond EBS):
```bash
# Option 1: Application-level encryption (LUKS)
# Inside EC2 instance
sudo cryptsetup luksFormat /dev/xvdb --key-file=/root/encryption.key
sudo cryptsetup luksOpen /dev/xvdb encrypted-vol --key-file=/root/encryption.key
sudo mkfs.ext4 /dev/mapper/encrypted-vol
sudo mount /dev/mapper/encrypted-vol /mnt/encrypted

# Option 2: Database-level encryption (if database running on EC2)
# PostgreSQL example
postgres=# CREATE EXTENSION pgcrypto;
postgres=# SELECT pgp_sym_encrypt('sensitive_data', 'encryption_key');
```

**Compliance Considerations**:
- **PCI-DSS**: Requires encryption in transit for cardholder data
- **HIPAA**: Requires encryption in transit for health information
- **GDPR**: Doesn't mandate encryption, but strongly recommended as safeguard

### Key Rotation & Lifecycle

**Automatic Key Rotation (AWS-Managed Keys)**

AWS automatically rotates AWS-managed keys annually:

```bash
# Check if automatic rotation is enabled
aws kms get-key-rotation-status \
  --key-id arn:aws:kms:us-east-1:123456789012:key/12345678-abcd-1234-abcd-123456789012
# Response: RotationEnabled: true
```

**Manual Key Rotation (Customer-Managed Keys)**

```bash
# Step 1: Create new CMK
aws kms create-key \
  --description "EBS encryption key - rotated" \
  --origin AWS_KMS

# Step 2: Update alias to point to new key
aws kms update-alias \
  --alias-name alias/ebs-prod-key \
  --target-key-id 87654321-dcba-4321-dcba-987654321098

# Note: Old key remains accessible for decryption of previously encrypted data

# Step 3: Verify no new data uses old key
aws kms describe-key \
  --key-id arn:aws:kms:us-east-1:123456789012:key/12345678-abcd-1234-abcd-123456789012
# Check CreationDate and verify no recent usage
```

**Re-encryption with New Key (Data Migration)**

```bash
# For EBS volume requiring re-encryption
# Step 1: Snapshot current volume
aws ec2 create-snapshot --volume-id vol-12345678

# Step 2: Decrypt snapshot (old key)
aws ec2 create-volume \
  --snapshot-id snap-12345678 \
  --availability-zone us-east-1a \
  --no-encrypted

# Step 3: Re-encrypt with new key
aws ec2 create-volume \
  --snapshot-id snap-decrypted-id \
  --availability-zone us-east-1a \
  --encrypted \
  --kms-key-id arn:aws:kms:us-east-1:123456789012:key/87654321-dcba-4321-dcba-987654321098

# Step 4: Hot-swap volumes during maintenance window
```

**Audit Trail for Key Usage**

```bash
# Enable CloudTrail for full KMS audit
aws cloudtrail create-trail \
  --name kms-audit-trail \
  --s3-bucket-name my-audit-bucket

# Query key usage
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=ResourceType,AttributeValue=AWS::KMS::Key \
  --max-results 50

# Example events logged:
# - Decrypt
# - GenerateDataKey
# - CreateGrant
# - DescribeKey
# - UpdateKeyDescription
```

---

## Placement Groups

### Placement Group Types

**1. Cluster Placement Group**

**Characteristics**:
- All instances in single AZ
- Instances placed on low-latency, high-bandwidth network fabric
- 10 Gbps to 100 Gbps inter-instance throughput
- < 1ms latency between instances

**Use Cases**:
- High-performance computing (HPC) simulations
- Tightly-coupled distributed systems (Hadoop, Spark clusters)
- Real-time collaborative applications (game servers with player proximity)
- Low-latency trading platforms

**Example Architecture**:
```
Cluster Placement Group in us-east-1a
├── Instance A (c5.4xlarge) - Worker 1
├── Instance B (c5.4xlarge) - Worker 2
├── Instance C (c5.4xlarge) - Worker 3
└── Instance D (c5.4xlarge) - Worker 4
     ↓
Total: 4 vCPUs × 4 = 16 vCPUs interconnected at < 1ms latency
```

**Limitations**:
- Single AZ only (failure of AZ = complete failure)
- Specific instance types supported (most C, M, R, and newer generations)
- Cannot span multiple regions
- Cannot add/remove instances from existing group (must recreate)

**Failure Implication**: Not suitable as primary deployment; use for:
- Batch processing pipelines (failures acceptable)
- Development/testing of HPC code
- Capacity reservation for temporary high-performance needs

**2. Spread Placement Group**

**Characteristics**:
- Instances distributed across distinct physical hardware
- Maximum 7 instances per placement group per AZ
- Fault isolation: hardware failure affects 1-2 instances
- Suitable for multi-AZ deployments

**Use Cases**:
- Highly available stateless services (web tier)
- Distributed databases requiring >= 3 replicas (e.g., Cassandra, MongoDB)
- Load-balanced services where single instance failure is tolerable
- Small to medium deployments requiring fault isolation

**Example Architecture**:
```
Spread Placement Group across us-east-1a, us-east-1b, us-east-1c
├── AZ-1a: Instance A (t3.medium) - Isolated Hardware #1
├── AZ-1a: Instance B (t3.medium) - Isolated Hardware #2
├── AZ-1b: Instance C (t3.medium) - Isolated Hardware #3
├── AZ-1b: Instance D (t3.medium) - Isolated Hardware #4
├── AZ-1c: Instance E (t3.medium) - Isolated Hardware #5
├── AZ-1c: Instance F (t3.medium) - Isolated Hardware #6
└── Availability: Any single hardware failure → only 1/6 instances affected
```

**Limitations**:
- Maximum 7 instances per AZ (practical max 21 for 3-AZ region)
- Not suitable for large-scale deployments
- Cannot co-locate multiple instances on same hardware

**Use in ASG**: Spread placement groups with ASG:
```bash
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name highly-available-web \
  --launch-template LaunchTemplateId=lt-12345678 \
  --min-size 3 \
  --max-size 7 \
  --desired-capacity 3 \
  --availability-zones us-east-1a us-east-1b us-east-1c \
  --placement-strategy '{"Type": "spread"}'
```

**3. Partition Placement Group**

**Characteristics**:
- Partitions instances across distinct hardware groups
- Up to 7 partitions per placement group
- Multiple instances can share a partition (unlike spread mode)
- Designed for distributed workloads with parallel data processing

**Use Cases**:
- Apache Hadoop (HDFS data locality optimization)
- Kafka clusters (broker distribution)
- Cassandra, HBase (distributed database replication)
- MapReduce workloads with data co-locality benefits

**Example Architecture**:
```
Partition Placement Group with 3 Partitions
├── Partition 1 (Rack 1): Instance A, B, C
│   └── Hardware: Isolated rack with dedicated network fabric
├── Partition 2 (Rack 2): Instance D, E, F
│   └── Hardware: Isolated rack with dedicated network fabric
└── Partition 3 (Rack 3): Instance G, H, I
    └── Hardware: Isolated rack with dedicated network fabric

Benefit: HDFS data locality - each partition holds replica of same data block
```

**Limitations**:
- Complex management (partition-aware application required)
- Limited to Hadoop-compatible workloads for full benefit
- Not suitable for non-distributed applications

**Advanced Feature - Partition Topology**:
```bash
aws ec2 describe-placement-groups \
  --group-names my-partition-group

# Output shows: Partition ID, instance count per partition
```

### Use Case Selection

**Decision Matrix**:

| Requirement | Cluster | Spread | Partition |
|------------|---------|--------|-----------|
| **Low latency** | ✅ < 1ms | ❌ > 10ms | ❌ > 10ms |
| **High bandwidth** | ✅ 100 Gbps | ❌ Standard | ❌ Standard |
| **Fault isolation** | ❌ Single AZ | ✅ Per instance | ✅ Per partition |
| **Large scale** | ❌ Dozen instances | ❌ Maximum 21 | ✅ Hundreds |
| **Multi-AZ** | ❌ Single AZ | ✅ 3+ AZ | ✅ 3+ AZ |
| **Distributed DB** | ❌ No locality | ✅ Minimal benefit | ✅ Data locality |

**Selection Guide**:

1. **Starts as default (no placement group)**
   - ASGs in multi-AZ configuration
   - Standard web applications, APIs
   - Stateless services
   - Sufficient for 90% of applications

2. **Choose Spread when**:
   - Need 3-6 instances with strict fault isolation
   - Need cross-AZ distribution
   - Example: Critical API backends, small HA clusters

3. **Choose Cluster when**:
   - Need < 1ms latency between instances
   - Workload is latency-sensitive (trading, simulations)
   - Cost of latency > cost of potential outage
   - Example: HPC cluster, real-time systems

4. **Choose Partition when**:
   - Deploying Hadoop, Kafka, Cassandra
   - Need data locality for performance
   - Deployed in single AZ for maximum locality benefit
   - Example: Data warehouse, analytics cluster

### Performance Optimization

**Cluster Placement Group Optimization**

```bash
# Enable enhanced networking for maximum performance
aws ec2 run-instances \
  --image-id ami-12345678 \
  --instance-type c5.4xlarge \
  --eni-specification DeviceIndex=0,InterfaceType=interface,AssociatePublicIpAddress=false \
  --placement-group my-cluster-pg \
  --network-interfaces '[{
    "DeviceIndex": 0,
    "AssociatePublicIpAddress": false,
    "DeleteOnTermination": true,
    "Ipv6AddressCount": 0,
    "Groups": ["sg-12345678"]
  }]'

# Verify ENA enabled
ethtool -i eth0 | grep driver
# Output: driver: ena (confirms Elastic Network Adapter)

# Test inter-instance bandwidth
# Instance A:
iperf -s

# Instance B:
iperf -c <instance-A-private-IP>
# Expected: 10-25 Gbps throughput
```

**Spread Placement Group Optimization**

```bash
# Monitor partition distribution
aws ec2 describe-instances \
  --filters 'Name=placement-group-name,Values=my-spread-pg' \
  --query 'Reservations[*].Instances[*].[InstanceId,Placement.AvailabilityZone]'

# Verify even distribution across AZs:
# Expected: Equal count in each AZ
```

**Partition Placement Group Optimization**

```bash
# Retrieve partition membership for Kafka/Hadoop configuration
aws ec2 describe-instances \
  --filters 'Name=placement-group-name,Values=my-partition-pg' \
  --query 'Reservations[*].Instances[*].[InstanceId,Placement.GroupName,Placement.PartitionNumber,Placement.AvailabilityZone]'

# Configure Kafka to use partition information for replica distribution
# Configure Hadoop to optimize data locality based on partition topology
```

### Multi-AZ Considerations

**Cluster + Multi-AZ (Not Possible)**
- Cluster groups are inherently single-AZ
- For multi-AZ HPC: Use separate cluster groups per AZ with cross-AZ replication (higher latency accepted)

**Spread + Multi-AZ**
```bash
# Spread placement group with ASG distributing across AZs
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name ha-service \
  --launch-template LaunchTemplateId=lt-12345678,Version='$Latest' \
  --min-size 3 \
  --max-size 3 \
  --desired-capacity 3 \
  --availability-zones us-east-1a us-east-1b us-east-1c \
  --placement-strategy '{"Type": "spread"}'

# Result: 1 instance per AZ (if 3 AZs available)
# Instances distributed across distinct hardware within each AZ
```

**Partition + Multi-AZ**
```bash
# Partition groups can span multiple AZs
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name hadoop-cluster \
  --launch-template LaunchTemplateId=lt-hadoop \
  --min-size 6 \
  --max-size 6 \
  --desired-capacity 6 \
  --availability-zones us-east-1a us-east-1b \
  --placement-strategy '{"Type": "partition", "MaxInstancesPerPartition": 2}'

# Result: 2 partitions (2 AZs) × 3 instances each
# Distributed but maintaining data locality per partition
```

---

## Auto Scaling Groups & Launch Configurations

### Launch Templates vs. Launch Configurations

**Launch Configuration (Legacy)**

- **Deprecated**: AWS doesn't recommend for new deployments
- **Immutable**: Cannot be modified after creation (must create new config)
- **Version control**: No built-in versioning
- **JSON format**: Limits compared to Launch Template

**Structure**:
```bash
aws autoscaling create-launch-configuration \
  --launch-configuration-name my-lc-v1 \
  --image-id ami-12345678 \
  --instance-type t3.micro \
  --key-name my-keypair \
  --security-groups sg-12345678 \
  --user-data file://user-data.sh \
  --spot-price 0.03
```

**Launch Template (Modern)**

- **Current standard**: Recommended for all new deployments
- **Versioning**: Support multiple versions with rollback capability
- **Mutable**: Can create new versions without affecting existing
- **Flexible**: Supports T2 unlimited credits, weighted capacity, mixed instance types

**Structure**:
```bash
aws ec2 create-launch-template \
  --launch-template-name my-template-v1 \
  --version-description "Initial release" \
  --launch-template-data '{
    "ImageId": "ami-12345678",
    "InstanceType": "t3.micro",
    "KeyName": "my-keypair",
    "SecurityGroupIds": ["sg-12345678"],
    "UserData": "IyEvYmluL2Jhc2gKLS1UZXN0IGRhdGE=",
    "Monitoring": {
      "Enabled": true
    },
    "IamInstanceProfile": {
      "Arn": "arn:aws:iam::123456789012:instance-profile/EC2-Role"
    },
    "CreditSpecification": {
      "CpuCredits": "unlimited"
    },
    "BlockDeviceMappings": [{
      "DeviceName": "/dev/xvda",
      "Ebs": {
        "VolumeSize": 30,
        "VolumeType": "gp3",
        "DeleteOnTermination": true,
        "Encrypted": true,
        "KmsKeyId": "arn:aws:kms:us-east-1:123456789012:key/..."
      }
    }]
  }'
```

**Key Differences**:

| Feature | Launch Configuration | Launch Template |
|---------|---------------------|-----------------|
| **Versioning** | No | Yes (implicit versions) |
| **Mutability** | Immutable | Create new version |
| **Mixed instances** | Single type only | Multiple types, weights |
| **T2 unlimited** | Basic support | Full support |
| **On-Demand/Spot mix** | Spot configuration only | More flexible mixing |
| **GPU support** | Limited | Full |
| **Metadata Options** | Not supported | IMDSv2 enforcement available |
| **Deprecation status** | Legacy (deprecated) | Current standard |

**Migration Strategy**:
```bash
# Step 1: Create Launch Template from existing LC
aws ec2 create-launch-template \
  --launch-template-name migrated-template \
  --version-description "Migrated from LC"
  # Manually copy settings from LC

# Step 2: Create ASG with new template
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name new-asg \
  --launch-template LaunchTemplateId=lt-12345678,Version='$Latest' \
  --min-size 1 \
  --max-size 3 \
  --desired-capacity 1

# Step 3: Gradually migrate instances
# Increase new ASG capacity, decrease old ASG capacity

# Step 4: Delete old ASG
aws autoscaling delete-auto-scaling-group \
  --auto-scaling-group-name old-asg \
  --force-delete
```

### Scaling Policies & Metrics

**Scaling Policy Types**

**1. Simple Scaling**
```bash
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name my-asg \
  --policy-name cpu-scale-up \
  --policy-type SimpleScaling \
  --adjustment-type ChangeInCapacity \
  --scaling-adjustment 1 \
  --cooldown 300

# Create CloudWatch alarm to trigger
aws cloudwatch put-metric-alarm \
  --alarm-name cpu-high \
  --alarm-actions arn:aws:autoscaling:us-east-1:123456789012:... \
  --metric-name CPUUtilization \
  --namespace AWS/EC2 \
  --statistic Average \
  --period 300 \
  --threshold 70 \
  --comparison-operator GreaterThanThreshold \
  --evaluation-periods 2
```

**Characteristics**:
- One action per alarm
- Single metric evaluation
- Problem: Can oscillate around threshold (example: CPU bounces 69-71%)

**2. Step Scaling** (Recommended for complex metrics)
```bash
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name my-asg \
  --policy-name cpu-scale-up-step \
  --policy-type StepScaling \
  --adjustment-type ChangeInCapacity \
  --metric-aggregation-type Average \
  --step-adjustments \
    'MetricIntervalLowerBound=0,MetricIntervalUpperBound=10,ScalingAdjustment=1' \
    'MetricIntervalLowerBound=10,MetricIntervalUpperBound=20,ScalingAdjustment=2' \
    'MetricIntervalLowerBound=20,ScalingAdjustment=3'

# Interpretation:
# - CPU 70-80% (0-10 above target): Scale +1 instance
# - CPU 80-90% (10-20 above target): Scale +2 instances
# - CPU > 90% (20+ above target): Scale +3 instances
```

**Advantages**:
- Progressive scaling respects workload severity
- Prevents under-scaling or over-scaling
- Reduces oscillation around threshold

**3. Target Tracking Scaling** (Recommended for most use cases)
```bash
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name my-asg \
  --policy-name target-tracking-cpu \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ASGAverageCPUUtilization"
    },
    "ScaleOutCooldown": 60,
    "ScaleInCooldown": 300
  }'

# Available predefined metrics:
# - ASGAverageCPUUtilization
# - ASGAverageNetworkIn
# - ASGAverageNetworkOut
# - ALBRequestCountPerTarget
# - ASGAverageDiskReadBytes
# - ASGAverageDiskWriteBytes
```

**Advantages**:
- AWS automatically adjusts capacity to maintain target metric
- No need for separate alarms
- ScaleOut (aggressive) and ScaleIn (conservative) independent cooldowns
- Low-operational overhead

**Custom Metric Scaling**:
```bash
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name my-asg \
  --policy-name target-tracking-custom \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "TargetValue": 100.0,
    "CustomizedMetricSpecification": {
      "MetricName": "QueueDepth",
      "Namespace": "MyApplication",
      "Statistic": "Average",
      "Unit": "Count"
    },
    "ScaleOutCooldown": 60,
    "ScaleInCooldown": 300
  }'

# Application pushes custom metric
aws cloudwatch put-metric-data \
  --namespace MyApplication \
  --metric-name QueueDepth \
  --value 256 \
  --unit Count \
   --dimensions Name=AutoScalingGroupName,Value=my-asg
```

**4. Scheduled Scaling**

For predictable traffic patterns (daily or weekly):

```bash
aws autoscaling put-scheduled-action \
  --auto-scaling-group-name my-asg \
  --scheduled-action-name morning-scale-up \
  --recurrence "0 6 * * MON-FRI" \
  --min-size 5 \
  --desired-capacity 10 \
  --max-size 20

# Scale down after business hours
aws autoscaling put-scheduled-action \
  --auto-scaling-group-name my-asg \
  --scheduled-action-name evening-scale-down \
  --recurrence "0 20 * * *" \
  --min-size 1 \
  --desired-capacity 2 \
  --max-size 5
```

**Metric Combinations**

For sophisticated scaling, use multiple policies:

```bash
# Policy 1: CPU-based scaling
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name my-asg \
  --policy-name cpu-tracking \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ASGAverageCPUUtilization"
    }
  }'

# Policy 2: Network-based scaling (rapid scale-out for traffic spikes)
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name my-asg \
  --policy-name network-tracking \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "TargetValue": 10000000,  # 10 MB/s
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ASGAverageNetworkIn"
    },
    "ScaleOutCooldown": 30,
    "ScaleInCooldown": 300
  }'

# Policy 3: Load balancer metrics (application-aware)
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name my-asg \
  --policy-name alb-request-tracking \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration  '{
    "TargetValue": 1000.0,  # Requests per target per minute
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ALBRequestCountPerTarget",
      "ResourceLabel": "app/my-load-balancer/50dc6c495c0c9188/targetgroup/my-targets/73e2d6bc24d8f067"
    }
  }'

# Result: ASG scales on whichever metric hits its threshold first
```

### Lifecycle Hooks

Lifecycle hooks enable custom actions during scale-out and scale-in:

```bash
# Create lifecycle hook for graceful termination
aws autoscaling put-lifecycle-hook \
  --auto-scaling-group-name my-asg \
  --lifecycle-hook-name graceful-shutdown \
  --lifecycle-transition autoscaling:EC2_INSTANCE_TERMINATING \
  --default-result CONTINUE \
  --heartbeat-timeout 300 \
  --notification-target-arn arn:aws:sns:us-east-1:123456789012:my-topic \
  --role-arn arn:aws:iam::123456789012:role/ASGLifecycleRole
```

**Workflow**:
```
Scale-down triggered
          ↓
Instance enters TERMINATING:WAIT state (holds for 300 seconds)
          ↓
SNS notification sent to handlers
          ↓
Custom code runs:
  1. Drain load balancer connections
  2. Complete in-flight requests
  3. Close database connections gracefully
          ↓
Handler calls: aws autoscaling complete-lifecycle-action
          ↓
Instance proceeds to TERMINATED state
```

**Implementation Example**:

Lambda function receiving hooktrigger:

```python
import boto3
import json

autoscaling = boto3.client('autoscaling')
elb = boto3.client('elbv2')

def lambda_handler(event, context):
    message = json.loads(event['Records'][0]['Sns']['Message'])
    instance_id = message['EC2InstanceId']
    asg_name = message['AutoScalingGroupName']
    hook_name = message['LifecycleHookName']
    
    print(f"Gracefully shutting down {instance_id} in {asg_name}")
    
    # Step 1: Deregister from load balancer (drain connections)
    # Find target group for this ASG
    targets = elb.describe_target_health(TargetGroupArn=...)
    for target in targets['TargetHealthDescriptions']:
        if target['Target']['Id'] == instance_id:
            print(f"Deregistering {instance_id} from load balancer")
            elb.deregister_targets(
                TargetGroupArn=...,
                Targets=[{'Id': instance_id}]
            )
            # Wait for connection drain (AWS NLB default: 30 seconds)
            time.sleep(30)
    
    # Step 2: Signal completion of lifecycle action
    autoscaling.complete_lifecycle_action(
        LifecycleActionResult='CONTINUE',
        LifecycleHookName=hook_name,
        AutoScalingGroupName=asg_name,
        InstanceId=instance_id
    )
    
    return {'statusCode': 200, 'body': 'Graceful shutdown completed'}
```

**Configuration Considerations**:
- **Heartbeat timeout**: Balance between grace period and scale-down speed (typical: 300-600 seconds)
- **Default result**: CONTINUE (proceed with termination, or ABANDON (abort termination if handler fails)
- **Notification target**: SNS topic or SQS queue for scalability

### Cost Optimization Through Scaling

**Mix On-Demand with Spot Instances**

```bash
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name cost-optimized-asg \
  --launch-template LaunchTemplateId=lt-12345678 \
  --mixed-instances-policy '{
    "LaunchTemplate": {
      "LaunchTemplateSpecification": {
        "LaunchTemplateId": "lt-12345678",
        "Version": "$Latest"
      },
      "Overrides": [
        {
          "InstanceType": "t3.large",
          "WeightedCapacity": 1
        },
        {
          "InstanceType": "t3a.large",
          "WeightedCapacity": 1
        },
        {
          "InstanceType": "m5.large",
          "WeightedCapacity": 1
        },
        {
          "InstanceType": "m5a.large",
          "WeightedCapacity": 1
        }
      ]
    },
    "InstancesDistribution": {
      "OnDemandPercentageAboveBaseCapacity": 20,
      "SpotAllocationStrategy": "price-capacity-optimized",
      "SpotInstancePools": 4,
      "SpotMaxPrice": "0.05"
    }
  }' \
  --min-size 2 \
  --max-size 20 \
  --desired-capacity 10
```

**Configuration Breakdown**:
- **OnDemandPercentageAboveBaseCapacity**: 20%
  - First 2 instances: On-Demand
  - Next 8 instances: 20% On-Demand (1-2), 80% Spot (6-7)
  - Provides reliability while reducing costs
  
- **SpotAllocationStrategy**: price-capacity-optimized
  - AWS selects Spot instances across availability zones
  - Balances price and interruption rate
  - More reliable than `lowest-price` strategy
  
- **SpotInstancePools**: 4
  - Diversify across 4 instance families to reduce termination risk
  
- **SpotMaxPrice**: 0.05
  - Don't exceed $0.05/hour for Spot

**Cost Savings**:
- Standard On-Demand t3.large: $0.0832/hour
- Spot t3.large: ~$0.025/hour (70% discount)
- Mix example: 2 On-Demand + 8 Spot = $0.367/hour (vs. $0.832 all On-Demand) = 55% savings

**Calculating Weighted Capacity**

When instances have different sizes in ASG:

```bash
# Configuration
# - Desired capacity: 10 units
# - t3.large (1 CPU): WeightedCapacity = 1
# - m5.large (2 CPU): WeightedCapacity = 2
# - c5.large (2 CPU): WeightedCapacity = 2

# Result:
# - 5 instances of t3.large = 5 capacity units
# - 2 instances of m5.large = 4 capacity units
# - 1 instance of c5.large = 2 capacity units
# Total: 11 units (exceeds desired 10, will terminate smallest weighted)
```

**Reserved Instances + Spot Combination**

```bash
# Purchase 2 Reserved Instances of t3.large (covers base load)
# Configure ASG with:
# - Minimum capacity: 2
# - Desired: 10
# - Maximum: 20
#
# - First 2 instances: Match Reserved Instance specifications
#   (baseline load, covered by RI, effectively free)
# - Next 8 instances: 20% On-Demand, 80% Spot
#   (variable load, most cost-effective)

# Monthly cost example
# Reserved: 2 × $50/month (pre-purchased)
# On-Demand: 1-2 × $60/month (20% of variable)
# Spot: 6-7 × $18/month (80% of variable)
# Total: ~$128/month (vs. $600 all On-Demand)
```

---

## Hands-On Scenarios

### Scenario 1: Deploying High-Availability Web Application

**Objective**: Deploy a 3-tier web application (Load Balancer → Web Tier → Database) across multiple AZs with auto-scaling.

**Architecture**:
```
Route53 (DNS)
    ↓
Application Load Balancer (AZ-1a, AZ-1b, AZ-1c)
    ↓
Auto Scaling Group (Web Tier)
├── AZ-1a: 2-3 instances (t3.medium)
├── AZ-1b: 2-3 instances (t3.medium)
└── AZ-1c: 2-3 instances (t3.medium)
    ↓
RDS Multi-AZ (Managed)
```

**Steps**:

1. **Create VPC and Subnets**
```bash
aws ec2 create-vpc --cidr-block 10.0.0.0/16
aws ec2 create-subnet --vpc-id vpc-12345678 --cidr-block 10.0.1.0/24 --availability-zone us-east-1a
aws ec2 create-subnet --vpc-id vpc-12345678 --cidr-block 10.0.2.0/24 --availability-zone us-east-1b
aws ec2 create-subnet --vpc-id vpc-12345678 --cidr-block 10.0.3.0/24 --availability-zone us-east-1c
```

2. **Create Security Groups**
```bash
# ALB Security Group
aws ec2 create-security-group \
  --group-name alb-sg \
  --description "ALB security group" \
  --vpc-id vpc-12345678

aws ec2 authorize-security-group-ingress \
  --group-id sg-alb \
  --protocol tcp --port 80 --cidr 0.0.0.0/0

aws ec2 authorize-security-group-ingress \
  --group-id sg-alb \
  --protocol tcp --port 443 --cidr 0.0.0.0/0

# EC2 Security Group
aws ec2 create-security-group \
  --group-name web-sg \
  --description "Web tier security group" \
  --vpc-id vpc-12345678

aws ec2 authorize-security-group-ingress \
  --group-id sg-web \
  --protocol tcp --port 80 --source-group sg-alb

aws ec2 authorize-security-group-ingress \
  --group-id sg-web \
  --protocol tcp --port 22 --cidr 10.0.0.0/16  # SSH from bastion
```

3. **Create Launch Template**
```bash
aws ec2 create-launch-template \
  --launch-template-name web-tier-v1 \
  --launch-template-data '{
    "ImageId": "ami-0c2b8ca1fac6ddb2",
    "InstanceType": "t3.medium",
    "KeyName": "my-keypair",
    "SecurityGroupIds": ["sg-web"],
    "Monitoring": {
      "Enabled": true
    },
    "IamInstanceProfile": {
      "Arn": "arn:aws:iam::123456789012:instance-profile/web-tier-role"
    },
    "UserData": "IyEvYmluL2Jhc2gKYXB0LWdldCB1cGRhdGUKYXB0LWdldCBpbnN0YWxsIC15IGFwYWNoZTI="
  }'
```

4. **Create Application Load Balancer**
```bash
aws elbv2 create-load-balancer \
  --name web-alb \
  --subnets subnet-1a subnet-1b subnet-1c \
  --security-groups sg-alb \
  --scheme internet-facing

aws elbv2 create-target-group \
  --name web-targets \
  --protocol HTTP \
  --port 80 \
  --vpc-id vpc-12345678 \
  --health-check-enabled \
  --health-check-protocol HTTP \
  --health-check-path / \
  --health-check-interval-seconds 30 \
  --health-check-timeout-seconds 5 \
  --healthy-threshold-count 2 \
  --unhealthy-threshold-count 3

aws elbv2 create-listener \
  --load-balancer-arn arn:aws:elasticloadbalancing:... \
  --protocol HTTP \
  --port 80 \
  --default-actions Type=forward,TargetGroupArn=arn:aws:elasticloadbalancing:...
```

5. **Create Auto Scaling Group**
```bash
aws autoscaling create-auto-scaling-group \
  --auto-scaling-group-name web-asg \
  --launch-template LaunchTemplateId=lt-12345678,Version='$Latest' \
  --min-size 2 \
  --desired-capacity 3 \
  --max-size 10 \
  --vpc-zone-identifier "subnet-1a,subnet-1b,subnet-1c" \
  --target-group-arns arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/web-targets/... \
  --default-cooldown 300 \
  --termination-policies Default

# Add scaling policies
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name web-asg \
  --policy-name target-tracking-cpu \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration '{
    "TargetValue": 70.0,
    "PredefinedMetricSpecification": {
      "PredefinedMetricType": "ASGAverageCPUUtilization"
    },
    "ScaleOutCooldown": 60,
    "ScaleInCooldown": 300
  }'
```

6. **Verify Deployment**
```bash
# Check ALB status
aws elbv2 describe-load-balancers --names web-alb

# Check ASG capacity
aws autoscaling describe-auto-scaling-groups --auto-scaling-group-names web-asg

# Test connectivity
curl http://<ALB-DNS-name>
```

### Scenario 2: Cross-Region Disaster Recovery

**Objective**: Replicate infrastructure from primary region (us-east-1) to disaster recovery region (us-west-2) with automated failover.

**Architecture**:
```
Primary Region (us-east-1)        DR Region (us-west-2)
├── EC2 ASG                        ├── EC2 ASG (scaled down)
├── RDS Primary                    ├── RDS Read Replica
└── Route53 Health Checks          └── Standby resources
```

**Steps**:

1. **Copy AMI to DR Region**
```bash
# Get AMI from primary region
aws ec2 describe-images \
  --image-ids ami-primary \
  --region us-east-1

# Copy to DR region with encryption
aws ec2 copy-image \
  --source-region us-east-1 \
  --source-image-id ami-primary \
  --destination-region us-west-2 \
  --name "web-app-dr-$(date +%Y%m%d)" \
  --encrypted \
  --kms-key-id arn:aws:kms:us-west-2:...

# Wait for copy completion
aws ec2 wait image-available \
  --image-ids ami-dr-12345678 \
  --region us-west-2
```

2. **Create DR Launch Template in Destination Region**
```bash
aws ec2 create-launch-template \
  --launch-template-name web-tier-dr-v1 \
  --region us-west-2 \
  --launch-template-data '{
    "ImageId": "ami-dr-12345678",
    "InstanceType": "t3.small",  # Smaller instances in standby
    "KeyName": "my-keypair",
    "SecurityGroupIds": ["sg-dr-web"],
    ...
  }'
```

3. **Set Up RDS Read Replica**
```bash
# Create read replica in DR region
aws rds create-db-instance-read-replica \
  --db-instance-identifier prod-db-dr \
  --source-db-instance-identifier arn:aws:rds:us-east-1:123456789012:db:prod-db \
  --db-instance-class db.t3.medium \
  --region us-west-2

# Monitor replication lag
aws rds describe-db-instances \
  --db-instance-identifier prod-db-dr \
  --region us-west-2 \
  --query 'DBInstances[0].StatusInfos'
```

4. **Create Route53 Health Checks**
```bash
# Health check on primary ALB
aws route53 create-health-check \
  --type HTTP \
  --alarm-identifier arn:aws:cloudwatch:us-east-1:123456789012:alarm:alb-health

# Failover routing policy
aws route53 change-resource-record-sets \
  --hosted-zone-id Z12345678 \
  --change-batch '{
    "Changes": [
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "app.example.com",
          "Type": "A",
          "SetIdentifier": "Primary",
          "Failover": "PRIMARY",
          "AliasTarget": {
            "DNSName": "web-alb-primary.us-east-1.elb.amazonaws.com",
            "HostedZoneId": "Z35SXDOTRQ7X7K"
          },
          "HealthCheckId": "health-check-primary"
        }
      },
      {
        "Action": "CREATE",
        "ResourceRecordSet": {
          "Name": "app.example.com",
          "Type": "A",
          "SetIdentifier": "DR",
          "Failover": "SECONDARY",
          "AliasTarget": {
            "DNSName": "web-alb-dr.us-west-2.elb.amazonaws.com",
            "HostedZoneId": "Z1H1FL5HABSF5"
          },
          "EvaluateTargetHealth": true
        }
      }
    ]
  }'
```

5. **Test Failover**
```bash
# Simulate primary failure
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name web-asg-primary \
  --desired-capacity 0  # Scale down primary

# Verify DNS resolution switches to DR
dig app.example.com +short
# Should return DR ALB IP

# Scale up primary again
aws autoscaling set-desired-capacity \
  --auto-scaling-group-name web-asg-primary \
  --desired-capacity 3
```

---

## Interview Questions

### Foundational Questions

**Q1: What is the difference between an AMI, snapshot, and backup?**

**A**: 
- **AMI**: Template for launching EC2 instances, includes OS, applications, configurations. Region-specific, requires copying for cross-region use.
- **Snapshot**: Point-in-time copy of a single EBS volume's data. Incremental, stored in S3. Can create volumes from snapshots but doesn't include OS or apps (data only).
- **Backup**: Comprehensive copies of entire instance state, typically includes multiple volumes, configurations, etc. More comprehensive than snapshots.

*Follow-up*: Explain the 3-2-1 backup strategy in AWS context.

---

**Q2: When would you use Spread vs. Partition vs. Cluster placement groups?**

**A**:
- **Spread**: 3-6 instances needing fault isolation. Each on distinct hardware. Example: HA web tier (If one hardware fails, only 1-2 instances lost).
- **Partition**: Distributed systems like Hadoop, Kafka. Instances grouped in partitions with data locality. Hundreds of instances possible.
- **Cluster**: High-performance computing, < 1ms latency required. Single AZ, tightly coupled systems. Example: HPC simulations, tightly-coupled distributed computing.

*Follow-up*: What are placement group limitations, and how would you design around them?

---

**Q3: Explain the difference between Launch Templates and Launch Configurations. Why did AWS deprecate LC?**

**A**:
- **Launch Configuration**: Immutable, no versioning, legacy creation. Cannot be modified (new LC required).
- **Launch Template**: Versioned, supports multiple changes, modern standard. Can create new versions without affecting existing.
- **Deprecation reason**: LC limitations prevent modern scaling patterns (mixed instance types, weight-based capacity, flexible Spot/On-Demand mixing).

*Follow-up*: How would you migrate from LC to LT with zero downtime?

---

### Advanced Scenario Questions

**Q4: How would you implement graceful shutdown of instances in a load-balanced application?**

**A**: Use ASG Lifecycle Hooks with Lambda/SNS:
1. Configure lifecycle hook on TERMINATING event (300-second timeout)
2. Lambda function receives termination notification
3. Lambda deregisters instance from ALB target group (triggers connection drain, 30 seconds default)
4. Lambda waits for drain completion, then signals completion of lifecycle action
5. Instance gracefully terminates

```bash
# Prevents dropped connections during scale-down
# Critical for stateful protocols (WebSocket, long-polling)
```

*Follow-up*: How would you handle database connection pooling during graceful shutdown?

---

**Q5: Design a cost-optimized infrastructure for a bursty application that has baseline load of 2 instances and peak load of 20 instances.**

**A**:
```
Baseline (2 instances): 
  - 2 Reserved Instances (t3.large)
  - Monthly commitment: ~$50/month
  - Coverage: Always-on baseline load

Variable (0-18 additional instances):
  - 80% Spot instances (m5.large, m5a.large, t3a.large)
  - 20% On-Demand instances (safety buffer)
  - Spot savings: ~70% vs. On-Demand
  - Enables rapid scale-out without capacity issues

Estimated monthly cost:
  - Baseline: $50 (RI)
  - Variable peak: 18 instances × $0.60 On-Demand OR $0.18 Spot (average)
  - RI cost is "sunk", variable scales with demand
```

*Follow-up*: How would you handle Spot termination events in this design?

---

**Q6: A production application's ASG is oscillating between min and max capacity (thrashing). How would you diagnose and fix this?**

**A**:
**Diagnosis**:
```bash
# Check ASG activity history
aws autoscaling describe-scaling-activities \
  --auto-scaling-group-name my-asg \
  --max-records 20

# Check CloudWatch metrics
aws cloudwatch get-metric-statistics \
  --metric-name GroupDesiredCapacity \
  --namespace AWS/AutoScaling \
  --start-time 2025-03-01T00:00:00Z \
  --end-time 2025-03-06T00:00:00Z \
  --period 300 \
  --statistics Average
```

**Causes**:
- Scaling policy threshold too close to baseline metric (e.g., CPU target = 50% but baseline = 48%)
- Cooldown period too short (allows overlapping scaling actions)
- Single metric isn't representative (CPU alone may not reflect actual bottleneck)

**Fixes**:
```bash
# Option 1: Increase cooldown period
aws autoscaling update-auto-scaling-group \
  --auto-scaling-group-name my-asg \
  --default-cooldown 600  # 10 minutes instead of 5

# Option 2: Change to target tracking (AWS handles smoothing)
aws autoscaling put-scaling-policy \
  --auto-scaling-group-name my-asg \
  --policy-type TargetTrackingScaling \
  --target-tracking-configuration {...}

# Option 3: Adjust threshold with safety margin
# Target = 70%, but scale when CPU > 75% (avoids oscillation around 70%)
```

*Follow-up*: Explain how target tracking scaling prevents oscillation vs. simple scaling.

---

### Technical Deep-Dives

**Q7: Walk through encrypting an EBS volume for an existing running application.**

**A**:
```
Step 1: Create snapshot of current volume
  aws ec2 create-snapshot --volume-id vol-12345678

Step 2: Wait for snapshot completion
  aws ec2 wait snapshot-completed --snapshot-ids snap-12345678

Step 3: Create encrypted volume from snapshot
  aws ec2 create-volume \
    --snapshot-id snap-12345678 \
    --availability-zone us-east-1a \
    --encrypted \
    --kms-key-id arn:aws:kms:us-east-1:123456789012:key/...

Step 4: Stop instance (brief downtime required)
  aws ec2 stop-instances --instance-ids i-12345678
  aws ec2 wait instance-stopped --instance-ids i-12345678

Step 5: Detach old volume
  aws ec2 detach-volume --volume-id vol-12345678

Step 6: Identify current device mapping
  aws ec2 describe-instances --instance-ids i-12345678 \
    --query 'Reservations[0].Instances[0].BlockDeviceMappings'
  # Output: Device name is typically /dev/xvda or /dev/sda1

Step 7: Attach encrypted volume with same device name
  aws ec2 attach-volume \
    --volume-id vol-encrypted-new \
    --instance-id i-12345678 \
    --device /dev/xvda

Step 8: Start instance
  aws ec2 start-instances --instance-ids i-12345678
  aws ec2 wait instance-running --instance-ids i-12345678

Step 9: Verify filesystem mounted correctly
  # SSH into instance, check mount points

Step 10: Delete old unencrypted volume (after verification)
  aws ec2 delete-volume --volume-id vol-12345678

Total downtime: ~3-5 minutes
Prerequisite: Application must be stateless or data synced elsewhere
```

*Follow-up*: How would you achieve zero-downtime encryption using blue-green deployment?

---

**Q8: Explain how Auto Scaling Group instance refresh works and when you'd use it.**

**A**:
```
Instance Refresh: Gradually replace instances in ASG with new Launch Template version

Workflow:
1. Update Launch Template (new AMI, instance type, security group, etc.)
2. Initiate instance refresh
   aws autoscaling start-instance-refresh \
     --auto-scaling-group-name my-asg \
     --instance-refresh-strategy Rolling \
     --preferences '{
       "MinHealthyPercentage": 90,
       "InstanceWarmupSeconds": 300
     }'

3. ASG gradually terminates old instances, launches new ones:
   Time T0: 10 instances (all old)
   Time T0+5min: 9 old, 1 new (90% healthy minimum maintained)
   Time T0+10min: 8 old, 2 new
   ...
   Time T0+50min: 0 old, 10 new

4. New instances are warm-checked before old ones terminated
   - Health check passes (ALB)
   - Instance stable for 300 seconds (InstanceWarmup)
   - Then old instance is terminated

When to use:
- Deploying new AMI without downtime
- Changing instance types in existing ASG
- Updating security group rules
- Modifying EBS configurations
- Updating IAM role
```

*Follow-up*: How do you handle persistent state during instance refresh?

---

**Q9: Design a multi-region, multi-AZ architecture for a SaaS application with compliance requirements (GDPR, data residency).**

**A**:
```
Architecture:

Primary:
├── Region: us-east-1 (Customer data location)
├── Subnets: us-east-1a, us-east-1b, us-east-1c (3 AZs)
├── ASG: 3-10 web instances + 3-10 API instances
├── RDS: Multi-AZ (primary in 1a, standby in 1b)
├── S3 Bucket: us-east-1 (default region)
├── Encryption: KMS CMK for all data at rest
└── Route53: Health checks on all endpoints

Secondary (Disaster Recovery only):
├── Region: Amazon EU (Ireland) for GDPR compliance
├── AMIs: Copied from primary, encrypted with EU KMS keys
├── Snapshots: Automated daily, encrypted, replicated
├── RDS: Read replica (standby for DR)
├── Backup Bucket: eu-west-1, versioned, encrypted
└── ASG: Scaled down (0-5 instances) for cost

Data Residency Controls:
├── Bucket policies: Block s3:GetObject outside EU region
├── VPC endpoints: No data egress through public internet
├── Route53 geolocation: Route EU customers to EU region
└── KMS key policies: Restrict decryption to specific regions

Automation:
├── CloudFormation: Infrastructure as Code for both regions
├── Lambda: Automated nightly snapshot copy to DR region
├── Systems Manager: Patch all instances in both regions
├── Health Checks: Automatic failover if primary region unhealthy

Compliance:
├── AWS Config: Monitor encryption status of all EBS volumes
├── CloudTrail: Log all API calls for audit (encrypted in S3)
├── VPC Flow Logs: Capture network traffic for GDPR investigations
└── Secrets Manager: Manage database credentials with automatic rotation
```

*Follow-up*: How would you handle active-active architecture across regions while maintaining data compliance?

---

**Q10: A critical production instance crashes repeatedly. Walk through your debugging process using EC2 tools.**

**A**:
```
Step 1: Check instance status
  aws ec2 describe-instances --instance-ids i-12345678 \
    --query 'Reservations[0].Instances[0].{State:State.Name,LaunchTime:LaunchTime,StatusChecks:StatusChecksFailed}'
  
  Possible states:
  - running (but checks fail) = OS-level issue
  - pending = Initialization issue
  - stopped = Crashed and stopped

Step 2: Inspect instance status checks
  aws ec2 describe-instance-status --instance-ids i-12345678
  
  Outcomes:
  - System status check failed = AWS infrastructure issue (rare)
  - Instance status check failed = OS/application issue (common)

Step 3: Review CloudWatch logs
  aws logs tail /aws/ec2/syslog --follow
  
  Look for:
  - Kernel panics
  - Out of memory (OOM) kills
  - Disk full errors
  - Service crashes

Step 4: Inspect system logs from EC2 console
  aws ec2 get-console-output --instance-id i-12345678

Step 5: Connect to instance (if running)
  # Via Session Manager (doesn't require SSH)
  aws ssm start-session --target i-12345678
  
  Check inside instance:
  - Disk utilization: df -h
  - Memory: free -h
  - Process crashes: dmesg | tail -50
  - Application logs: /var/log/application/

Step 6: If memory issue suspected
  Check for memory leaks:
    ps aux --sort=-%mem | head -10
  
  Check memory-induced crashes:
    dmesg | grep -i memory

Step 7: If recovery fails, snapshot volume for analysis
  aws ec2 create-snapshot --volume-id vol-12345678
  
  Later analyze snapshot offline

Step 8: Implement monitoring to prevent future crashes
  aws cloudwatch put-metric-alarm \
    --alarm-name high-memory-usage \
    --alarm-actions arn:aws:sns:... \
    --metric-name MemoryUtilization \
    --threshold 85
```

*Follow-up*: How would you automate recovery for predictable crash patterns?

---

This concludes the comprehensive Senior DevOps study guide for AWS Compute Services. The guide covers foundational concepts through advanced architectural patterns suitable for 5-10+ year DevOps engineers.

