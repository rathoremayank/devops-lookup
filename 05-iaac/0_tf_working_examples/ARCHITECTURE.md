# Infrastructure Architecture Documentation

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                          AWS Region (us-east-1)                    │
│                                                                     │
│  ┌────────────────────────────────────────────────────────────┐   │
│  │                   VPC (10.0.0.0/16)                         │   │
│  │                                                             │   │
│  │  ┌──────────────────────────────┐  ┌─────────────────────┐ │   │
│  │  │   Public Subnets             │  │  Internet Gateway   │ │   │
│  │  │  10.0.1.0/24 | 10.0.2.0/24   │  │                     │ │   │
│  │  │                               │  │ ◄──────┐            │ │   │
│  │  │  ┌─────────────────────────┐  │  │        │ 0.0.0.0/0 │ │   │
│  │  │  │  Master Node (t3.medium)│  │  │        │            │ │   │
│  │  │  │  • Kubernetes API:6443  │  │  │        │            │ │   │
│  │  │  │  • Elastic IP: <Public> │◄─┼──┼────────┘            │ │   │
│  │  │  │  • 10.0.1.X/24          │  │  │                     │ │   │
│  │  │  │  • Security Group: Master│  │  │                     │ │   │
│  │  │  └─────────────────────────┘  │  │                     │ │   │
│  │  │                               │  │                     │ │   │
│  │  └───────────────┬────────────────┘  └─────────────────────┘ │   │
│  │                  │                                             │   │
│  │  ┌──────────────────────────────┐                             │   │
│  │  │  NAT Gateways                │                             │   │
│  │  │  • 2x Elastic IPs            │                             │   │
│  │  │  • For outbound access       │                             │   │
│  │  └──────────────────────────────┘                             │   │
│  │                  │                                             │   │
│  │  ┌──────────────▼────────────────┐                             │  │
│  │  │  Private Subnets              │                             │  │
│  │  │  10.0.10.0/24 | 10.0.11.0/24  │                             │  │
│  │  │                               │                             │  │
│  │  │  ┌─────────────────────────┐  │                             │  │
│  │  │  │  Worker Node (t3.small) │  │                             │  │
│  │  │  │  • Kubelet:10250        │  │                             │  │
│  │  │  │  • NodePort:30000-32767 │  │                             │  │
│  │  │  │  • Elastic IP: <Public> │  │                             │  │
│  │  │  │  • 10.0.10.X/24         │  │                             │  │
│  │  │  │  • Security Group:Worker│  │                             │  │
│  │  │  └─────────────────────────┘  │                             │  │
│  │  │                               │                             │  │
│  │  └───────────────────────────────┘                             │  │
│  │                                                             │   │
│  └────────────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────────────┘
```

## Kubernetes Cluster Architecture

```
┌─────────────────────────────────────────────────┐
│         Kubernetes Cluster Setup                │
├─────────────────────────────────────────────────┤
│                                                 │
│  MASTER NODE                                    │
│  ├─ API Server          (6443)                  │
│  ├─ Controller Manager  (10252)                 │
│  ├─ Scheduler          (10251)                  │
│  ├─ etcd               (2379-2380)              │
│  ├─ kubelet            (10250)                  │
│  └─ Calico CNI Plugin                           │
│     └─ Pod Network: 192.168.0.0/16              │
│                                                 │
├─────────────────────────────────────────────────┤
│                                                 │
│  WORKER NODE #1                                 │
│  ├─ kubelet            (10250)                  │
│  ├─ kube-proxy         (NodePort access)        │
│  ├─ Calico CNI agent                            │
│  └─ API Server access   (6443 ← 10.0.1.X)     │
│                                                 │
└─────────────────────────────────────────────────┘
```

## Network Communication Flows

### 1. Pod-to-Pod Communication (Same Node)
```
Pod A (10.x.x.x) -> veth pair -> docker0/CNI -> Pod B (10.x.x.x)
```

### 2. Pod-to-Pod Communication (Different Nodes)
```
Worker 1 Pod (192.168.x.x) 
    ↓
Calico Tunnel (VXLAN)
    ↓
Worker 2 Pod (192.168.y.y)
```

### 3. External Access to Service
```
External Client
    ↓ :30000-32767 (NodePort)
    ↓
Worker Node Security Group
    ↓
Service Endpoint
    ↓
Pod
```

### 4. Worker to Master Communication
```
Worker (10.0.10.x) → Master (10.0.1.x):6443
```

## Security Groups Configuration

### Master Security Group (`master_sg`)

| Direction | Port | Protocol | Source | Purpose |
|-----------|------|----------|--------|---------|
| Inbound | 6443 | TCP | 0.0.0.0/0 | API Server |
| Inbound | 2379-2380 | TCP | 10.0.0.0/16 | etcd |
| Inbound | 10250 | TCP | 10.0.0.0/16 | kubelet |
| Inbound | 10251 | TCP | 10.0.0.0/16 | Scheduler |
| Inbound | 10252 | TCP | 10.0.0.0/16 | Controller Manager |
| Inbound | 22 | TCP | 0.0.0.0/0 | SSH |
| Inbound | All | TCP | Worker SG | From Workers |
| Egress | 0-65535 | ALL | 0.0.0.0/0 | All traffic out |

### Worker Security Group (`worker_sg`)

| Direction | Port | Protocol | Source | Purpose |
|-----------|------|----------|--------|---------|
| Inbound | 10250 | TCP | 10.0.0.0/16 | kubelet |
| Inbound | 30000-32767 | TCP | 0.0.0.0/0 | NodePort |
| Inbound | 22 | TCP | 0.0.0.0/0 | SSH |
| Inbound | All | TCP | Master SG | From Master |
| Egress | 0-65535 | ALL | 0.0.0.0/0 | All traffic out |

## Route Table Configuration

### Public Route Table
```
Destination     │ Target
────────────────┼─────────────────────
10.0.0.0/16     │ Local (VPC)
0.0.0.0/0       │ Internet Gateway (igw-xxx)
```

### Private Route Table (Per NAT Gateway)
```
Destination     │ Target
────────────────┼──────────────────────
10.0.0.0/16     │ Local (VPC)
0.0.0.0/0       │ NAT Gateway (natgw-xxx)
```

## Data Flow Diagrams

### Cluster Initialization Flow

```
1. Terraform Apply
        ↓
2. VPC & Network Components Created
        ↓
3. Master EC2 Instance Launched (us-east-1a)
        ├─ Cloud-init begins
        ├─ Docker installed
        ├─ Kubernetes packages installed
        └─ Master initialization script runs
        ↓
4. kubeadm init
        ├─ Kubernetes certificates generated
        ├─ Control plane pods started
        └─ etcd initialized
        ↓
5. CNI (Calico) Deployed
        ├─ Pod network: 192.168.0.0/16
        └─ Network policies enabled
        ↓
6. Join Token Generated
        ↓
7. Worker EC2 Instance Launched (us-east-1b)
        ├─ Cloud-init begins
        ├─ Docker installed
        ├─ Kubernetes packages installed
        └─ Worker initialization script runs
        ↓
8. kubeadm join
        ├─ Connects to Master API (6443)
        ├─ Retrieves token
        └─ Joins cluster
        ↓
9. Worker Registration
        ├─ Node added to cluster
        └─ Ready for pod deployment
```

### Traffic Flow: kubectl apply

```
kubectl apply → API Server (6443)
            ↓
    Authentication & Authorization
            ↓
    Request to Master (etcd)
            ↓
    Controller Manager processes
            ↓
    Scheduler assigns pod to node
            ↓
    kubelet on Worker receives
            ↓
    Docker pulls image
            ↓
    Container started
            ↓
    CNI assigns IP from pod network
            ↓
    Pod ready
```

## Kubernetes Service Architecture

### Service DNS Resolution Example
```
Pod in Kubernetes
    ↓
DNS Query: nginx.default.svc.cluster.local
    ↓
kube-dns/CoreDNS (in kube-system namespace)
    ↓
Service IP: 10.96.x.x (cluster IP from service subnet)
    ↓
Packet forwarded via kube-proxy
    ↓
load balanced to backend pods
```

## Resource Lifecycle

### Master Node Lifecycle
```
EC2 Instance Created
        ↓
Cloud-init exec (common-bootstrap.sh + master-init.sh)
        ↓
Docker daemon started
        ↓
kubelet service started
        ↓
kubeadm init creates control plane
        ↓
Calico DaemonSet deployed
        ↓
Master Ready (kubectl get nodes shows Ready)
```

### Worker Node Lifecycle
```
EC2 Instance Created
        ↓
Cloud-init exec (common-bootstrap.sh + worker-init.sh)
        ↓
Docker daemon started
        ↓
kubelet service started
        ↓
kubeadm join connects to master
        ↓
kubelet reports to API Server
        ↓
Calico agent deployed
        ↓
Worker Ready (kubelet registers node)
```

## IP Plan

### VPC CIDR: 10.0.0.0/16

| Subnet Type | AZ | CIDR | Range | Purpose |
|-------------|----|----|-------|---------|
| Public | us-east-1a | 10.0.1.0/24 | 10.0.1.0-255 | Master, IGW |
| Public | us-east-1b | 10.0.2.0/24 | 10.0.2.0-255 | Spare |
| Private | us-east-1a | 10.0.10.0/24 | 10.0.10.0-255 | Worker 1 |
| Private | us-east-1b | 10.0.11.0/24 | 10.0.11.0-255 | Worker 2+ |

### Service Subnet: 10.96.0.0/12
- Range: 10.96.0.0 to 10.111.255.255
- Used for: Kubernetes Service ClusterIPs
- DNS: 10.96.0.10 (kubernetes-dns)

### Pod Network (Calico): 192.168.0.0/16
- Range: 192.168.0.0 to 192.168.255.255
- Used for: Pod IPs across all nodes
- Default block size: /26 per node

## Scaling Architecture

### Horizontal Scaling (Add Worker Nodes)
```
For each new worker:
1. Duplicate worker module in main.tf
2. Create new EC2 instance in private subnet
3. kubeadm join to cluster
4. Calico automatically assigns pod subnet block

Supports: 1K+ worker nodes
```

### Vertical Scaling (Larger Instances)
```
Change variables:
- master_instance_type = "t3.large"
- worker_instance_type = "t3.medium"

Supports: multi-core, more memory
```

### High Availability Setup (Not included in base)
```
For HA Master:
1. Deploy 3 master nodes (odd number for etcd quorum)
2. Deploy load balancer for API server (6443)
3. Configure external etcd (optional)

For HA Workers:
1. Deploy auto-scaling group
2. NLB for service distribution
3. Pod Disruption Budgets for graceful scaling
```

## Monitoring Points

### System-Level Metrics
- EC2 CPU, Memory, Disk, Network
- CloudWatch monitoring enabled
- Custom metrics can be added

### Kubernetes Metrics
- Node status and capacity
- Pod CPU/Memory usage
- API latency and request count
- etcd performance metrics

### Application Logs
- kubelet logs: `/var/log/kubelet.log`
- API Server logs: kubectl logs in kube-apiserver pod
- Worker node logs: CloudWatch Logs agent

## Disaster Recovery

### Backup Strategy
- etcd backups (daily recommended)
- Cluster configuration via Terraform state
- Application manifests in version control

### Recovery Procedures
- Master node failure: Re-run terraform apply
- Worker node failure: Drain node, terraform destroy instance
- Complete cluster failure: terraform destroy && terraform apply

### State Management
- Terraform state in S3 (recommended)
- DynamoDB locks for concurrent operations
- etcd separately backed up

## Performance Considerations

### Network
- VPC throughput: Up to 100 Gbps
- NAT Gateway: Up to 45 Gbps per AZ
- ENI throughput: Based on instance type
- Pod-to-pod: ~10 microseconds latency (VXLAN)

### Storage
- EBS volumes encrypted by default
- gp3 recommended for Kubernetes (3K IOPS, 125 MB/s free)
- Attach multiple volumes for persistence

### Compute
- Master: Recommend t3.medium+ (2 vCPU, 4GB RAM)
- Worker: Recommend t3.small+ (2 vCPU, 2GB RAM)
- Node size determines pod density

## Cost Optimization

### Instance Sizing
- Master: 1x t3.medium = $0.0416/hour
- Worker: 1x t3.small = $0.0208/hour
- Total: ~$32/month for 1 master + 1 worker

### Optimization Opportunities
- Use Spot Instances for workers (70% discount)
- Use Reserved Instances for masters (40% discount)
- Implement auto-scaling to reduce idle resources
- Use Graviton instances (ARM-based, cheaper)

### Cost Breakdown
- EC2 instances: 60%
- Elastic IPs: 15%
- NAT Gateway: 15%
- Data transfer: 10%

## Architecture Best Practices Implemented

✅ Multi-AZ aware (can expand)
✅ High availability networking (NAT per AZ)
✅ Security group segmentation
✅ Private subnets for workers
✅ Encryption enabled (EBS)
✅ CloudWatch monitoring enabled
✅ Modular Terraform structure
✅ Version-controlled infrastructure
✅ Easy to scale horizontally
✅ Environment separation (dev/prod)

## Future Enhancements

- [ ] Multi-master HA setup
- [ ] Auto-scaling groups with Karpenter
- [ ] Service mesh (Istio/Linkerd)
- [ ] Ingress controller with ALB
- [ ] Persistent storage (EBS CSI driver)
- [ ] Container registry (ECR)
- [ ] GitOps with ArgoCD
- [ ] Observability stack (Prometheus/Grafana)
- [ ] Service accounts and RBAC
- [ ] Network policies (Calico)
