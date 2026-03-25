# Modular Kubernetes Cluster Terraform Project

A production-ready, modular Terraform project for deploying a Kubernetes cluster on AWS with 1 master and 1 worker node, complete with networking infrastructure.

📖 **New to this project?** Start with [FILE_INDEX.md](FILE_INDEX.md) for quick navigation to what you need.

## Quick Links

- 🚀 **[QUICKSTART.md](QUICKSTART.md)** - Deploy in 9 steps
- 🏗️ **[ARCHITECTURE.md](ARCHITECTURE.md)** - System design and components  
- ⚙️ **[BACKEND_SETUP.md](BACKEND_SETUP.md)** - Remote state configuration
- ⚠️ **[CLEANUP_GUIDE.md](CLEANUP_GUIDE.md)** - **Read before cleanup!**
- 📑 **[FILE_INDEX.md](FILE_INDEX.md)** - Complete navigation guide

## Project Structure

```
0_tf_working_examples/
├── modules/
│   ├── networking/
│   │   ├── main.tf           # VPC, subnets, route tables, security groups
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── ec2/
│   │   ├── main.tf           # EC2 instance provisioning
│   │   ├── variables.tf
│   │   └── outputs.tf
│   └── kubernetes/
│       ├── main.tf           # Kubernetes initialization logic
│       ├── variables.tf
│       ├── outputs.tf
│       └── scripts/
│           ├── common-bootstrap.sh    # Common setup for all nodes
│           ├── master-init.sh         # Master node initialization
│           └── worker-init.sh         # Worker node initialization
└── environments/
    └── dev/
        ├── versions.tf       # Provider configuration
        ├── main.tf          # Module instantiation
        ├── variables.tf     # Variable declarations
        ├── outputs.tf       # Root outputs
        └── terraform.tfvars # Default values
```

## Module Descriptions

### Networking Module (`modules/networking/`)

Creates AWS networking infrastructure:
- **VPC**: Custom VPC with configurable CIDR block
- **Public Subnets**: For master node and bastion access
- **Private Subnets**: For worker nodes
- **Internet Gateway**: For outbound internet access
- **NAT Gateways**: For private subnet internet access
- **Route Tables**: Public and private routing rules
- **Security Groups**: 
  - Master SG: Allows Kubernetes API (6443), etcd (2379-2380), kubelet (10250), scheduler (10251), controller-manager (10252)
  - Worker SG: Allows kubelet (10250), NodePort services (30000-32767)
  - Cross-communication between master and workers

**Key Outputs:**
- `vpc_id`: VPC identifier
- `public_subnet_ids`: List of public subnet IDs
- `private_subnet_ids`: List of private subnet IDs
- `master_security_group_id`: Master SG ID
- `worker_security_group_id`: Worker SG ID

### EC2 Module (`modules/ec2/`)

Provisions EC2 instances with:
- Configurable instance type and AMI
- EBS root volume with encryption enabled
- Elastic IP assignment for public connectivity
- User data script execution for node initialization
- CloudWatch monitoring enabled
- Proper tagging and lifecycle management

**Inputs:**
- `instance_type`: EC2 instance type (e.g., t3.medium)
- `ami_id`: AMI ID to launch
- `subnet_id`: Subnet for instance placement
- `security_group_id`: Security group assignment
- `key_pair_name`: EC2 Key Pair for SSH access
- `user_data`: Initialization script

**Outputs:**
- `instance_id`: EC2 instance ID
- `instance_private_ip`: Private IP address
- `instance_public_ip`: Elastic IP
- `instance_dns`: DNS name

### Kubernetes Module (`modules/kubernetes/`)

Prepares Kubernetes initialization scripts:
- Generates user data scripts for master and worker nodes
- Configures Docker daemon
- Installs kubeadm, kubelet, kubectl
- Sets up system prerequisites (sysctl, swap disabled)
- Initializes master with kubeadm
- Prepares join tokens for workers
- Deploys Calico CNI plugin

**Bootstrap Scripts:**
- `common-bootstrap.sh`: System updates, Docker & Kubernetes package installation
- `master-init.sh`: Kubernetes control plane initialization, Calico deployment
- `worker-init.sh`: Worker node joining to the cluster

## Prerequisites

### Local Machine
- Terraform >= 1.0
- AWS CLI configured with credentials
- SSH key pair already created in AWS

### AWS Account
- EC2 Key Pair created (update `terraform.tfvars`)
- Appropriate IAM permissions for EC2, VPC, and EIP creation
- S3 bucket and DynamoDB table for remote state (optional but recommended)

## Usage

### 1. Initialize Prerequisites

Create an EC2 Key Pair in AWS:
```bash
aws ec2 create-key-pair --key-name my-key-pair --query 'KeyMaterial' --output text > ~/.ssh/my-key-pair.pem
chmod 600 ~/.ssh/my-key-pair.pem
```

### 2. Configure Terraform Variables

Edit `environments/dev/terraform.tfvars`:
```hcl
aws_region        = "us-east-1"
ec2_key_pair_name = "my-key-pair"  # Set to your key pair name
```

### 3. Initialize Terraform

```bash
cd environments/dev
terraform init
```

### 4. Review and Validate Configuration

```bash
terraform plan
terraform validate
```

### 5. Deploy Infrastructure

```bash
terraform apply
```

Review the plan and type `yes` to proceed.

### 6. Monitor Deployment

Get master node IP:
```bash
terraform output master_public_ip
```

SSH into master to check cluster status:
```bash
ssh -i ~/.ssh/my-key-pair.pem ubuntu@<MASTER_PUBLIC_IP>
```

Check cluster initialization on master:
```bash
sudo systemctl status kubelet
sudo kubeadm status
sudo kubectl get nodes
sudo kubectl get pods --all-namespaces
```

Monitor worker node initialization:
```bash
ssh -i ~/.ssh/my-key-pair.pem ubuntu@<WORKER_PUBLIC_IP>
sudo systemctl status kubelet
```

### 7. Access Kubernetes Cluster

Copy kubeconfig from master:
```bash
mkdir -p ~/.kube
scp -i ~/.ssh/my-key-pair.pem ubuntu@<MASTER_PUBLIC_IP>:/home/ubuntu/.kube/config ~/.kube/config-k8s
```

Use with kubectl:
```bash
KUBECONFIG=~/.kube/config-k8s kubectl get nodes
```

## Output Variables

After deployment, retrieve useful information:

```bash
terraform output master_public_ip          # Master node public IP
terraform output worker_public_ip          # Worker node public IP
terraform output master_private_ip         # Master node private IP
terraform output vpc_id                    # VPC identifier
terraform output pod_network_cidr          # Pod network CIDR
terraform output ssh_master_command        # SSH command for master
terraform output ssh_worker_command        # SSH command for worker
```

## Security Considerations

1. **SSH Access**: Security groups allow SSH (22) from anywhere (0.0.0.0/0). Restrict this to your IP:
   ```hcl
   # In networking/main.tf, modify the master and worker security groups
   cidr_blocks = ["YOUR_IP/32"]  # instead of ["0.0.0.0/0"]
   ```

2. **API Server**: Kubernetes API is exposed (6443). Use:
   - Network policies for pod-to-pod communication
   - RBAC for API server access control
   - Network ACLs to restrict API access

3. **Encryption**: 
   - EBS volumes are encrypted
   - Enable S3 encryption for Terraform state
   - Use AWS Secrets Manager for sensitive data

4. **IAM**: Create IAM roles for EC2 instances to access:
   - CloudWatch for logs
   - S3 for backups
   - AWS Systems Manager for patching

## Customization

### Scaling to Multiple Workers

To add more workers, duplicate the worker module in `environments/dev/main.tf`:

```hcl
module "worker_instance_2" {
  source = "../../modules/ec2"
  # ... configuration for second worker node
}
```

### Changing Kubernetes Version

Update in `terraform.tfvars`:
```hcl
kubernetes_version = "1.29.0"
```

### Modifying Network CIDR

Update in `terraform.tfvars`:
```hcl
vpc_cidr             = "172.16.0.0/16"
public_subnet_cidrs  = ["172.16.1.0/24", "172.16.2.0/24"]
private_subnet_cidrs = ["172.16.10.0/24", "172.16.11.0/24"]
pod_network_cidr     = "10.0.0.0/8"
```

### Deploying to Multiple Environments

Copy the `environments/dev` directory:
```bash
cp -r environments/dev environments/prod
```

Modify `environments/prod/terraform.tfvars` with production settings.

## Troubleshooting

### Master node initialization hangs

Check cloud-init logs:
```bash
ssh -i key.pem ubuntu@<MASTER_IP>
sudo tail -f /var/log/cloud-init-output.log
```

### Worker node fails to join

Verify master is ready:
```bash
sudo kubectl get nodes  # On master
```

Check worker logs:
```bash
ssh -i key.pem ubuntu@<WORKER_IP>
sudo journalctl -u kubelet -f
```

### Networking issues

Test connectivity from worker to master:
```bash
ssh -i key.pem ubuntu@<WORKER_IP>
nc -zv <MASTER_PRIVATE_IP> 6443
```

## Cleanup

To destroy all resources:

```bash
cd environments/dev
terraform destroy
```

Review the plan and type `yes` to confirm deletion.

## Advanced Topics

### Remote State Management

Uncomment the S3 backend in `versions.tf` and configure:

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "k8s-cluster/terraform.tfstate"
  region         = "us-east-1"
  encrypt        = true
  dynamodb_table = "terraform-locks"
}
```

Create the backend resources first:
```bash
# Create S3 bucket
aws s3 mb s3://your-terraform-state-bucket --region us-east-1

# Enable versioning
aws s3api put-bucket-versioning --bucket your-terraform-state-bucket \
  --versioning-configuration Status=Enabled

# Create DynamoDB table for locking
aws dynamodb create-table \
  --table-name terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### Monitoring and Logging

Configure CloudWatch monitoring:
1. Enable detailed monitoring (done in EC2 module)
2. Create CloudWatch Logs agent configuration
3. Monitor /var/log/kubelet logs
4. Set up alarms for high CPU/memory usage

### High Availability Setup

For production HA:
1. Add multiple master nodes (3-node etcd cluster)
2. Deploy load balancer for API server access
3. Use multi-AZ deployment
4. Modify `terraform.tfvars` to deploy in different AZs

## Documentation

Complete documentation is available in the following files:

- **[QUICKSTART.md](QUICKSTART.md)** - 9-step quick start guide
- **[ARCHITECTURE.md](ARCHITECTURE.md)** - Detailed architecture overview and design decisions
- **[BACKEND_SETUP.md](BACKEND_SETUP.md)** - S3 and DynamoDB remote state setup
- **[CLEANUP_GUIDE.md](CLEANUP_GUIDE.md)** - ⚠️ **Comprehensive guide for deleting backend resources** - READ BEFORE CLEANUP!
- **[CLEANUP_QUICK_REFERENCE.md](CLEANUP_QUICK_REFERENCE.md)** - Quick reference card for cleanup commands (print-friendly)
- **[CLEANUP_SAFETY_CHECKLIST.md](CLEANUP_SAFETY_CHECKLIST.md)** - Pre-cleanup verification checklist (team sign-off)
- **[scripts/README.md](scripts/README.md)** - Setup and cleanup script documentation
- **[SUMMARY.md](SUMMARY.md)** - Project summary and troubleshooting

## References

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [kubeadm Reference](https://kubernetes.io/docs/reference/setup-tools/kubeadm/)
- [Calico Documentation](https://docs.tigera.io/calico/latest/)
- [AWS Terraform Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [Terraform Module Documentation](https://www.terraform.io/language/modules)

## License

This project is provided as-is for educational and reference purposes.

## Support

For issues or questions:
1. Check Terraform logs: `terraform plan/apply -var-file=...`
2. Review bootstrap logs on instances
3. Check AWS CloudTrail for API errors
4. Verify security group rules and network policies
