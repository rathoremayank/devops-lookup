# Quick Start Guide - Kubernetes Cluster Deployment

## Prerequisites Checklist

- [ ] AWS Account with appropriate permissions
- [ ] AWS CLI configured: `aws configure`
- [ ] Terraform installed (>= 1.0): `terraform --version`
- [ ] SSH key pair created in AWS region

## Step 1: Create SSH Key Pair

```bash
# Create EC2 Key Pair in AWS
aws ec2 create-key-pair --key-name my-k8s-cluster --region us-east-1 \
  --query 'KeyMaterial' --output text > ~/.ssh/my-k8s-cluster.pem

# Set correct permissions
chmod 600 ~/.ssh/my-k8s-cluster.pem
```

## Step 2: Configure Terraform Variables

```bash
cd environments/dev

# Copy example variables
cp ../../example.tfvars terraform.tfvars

# Edit configuration
nano terraform.tfvars
# OR
vim terraform.tfvars
```

**Key settings to update:**
- `aws_region`: Your AWS region (e.g., us-east-1, us-west-2)
- `ec2_key_pair_name`: Name of the key pair you just created

## Step 3: Initialize Terraform

```bash
terraform init
```

This downloads the AWS provider and sets up the local working directory.

## Step 4: Validate Configuration

```bash
terraform validate
```

Returns success if configuration is valid.

## Step 5: Plan Deployment

```bash
terraform plan -out=tfplan
```

Review the resources that will be created:
- 1 VPC with public/private subnets
- Internet Gateway and NAT Gateways
- 1 Master node (t3.medium recommended)
- 1 Worker node (t3.small recommended)
- Security groups and route tables

Estimated cost will be displayed.

## Step 6: Deploy Infrastructure

```bash
terraform apply tfplan
```

Deployment takes 5-10 minutes. Watch for completion message.

## Step 7: Monitor Deployment

```bash
# Get outputs
terraform output

# Get master public IP
MASTER_IP=$(terraform output -raw master_public_ip)
echo "Master IP: $MASTER_IP"
```

## Step 8: Access Your Cluster

### SSH into Master Node

```bash
ssh -i ~/.ssh/my-k8s-cluster.pem ubuntu@<MASTER_PUBLIC_IP>
```

### Check Cluster Status

```bash
# Check node status
sudo kubectl get nodes

# Check pod status
sudo kubectl get pods --all-namespaces

# Watch kubelet initialization
sudo journalctl -u kubelet -f
```

### Get Join Command for Future Nodes

On master node:
```bash
cat /root/kubeadm-join-command.txt
```

## Step 9: Copy Kubeconfig to Local Machine

```bash
mkdir -p ~/.kube

scp -i ~/.ssh/my-k8s-cluster.pem \
  ubuntu@<MASTER_PUBLIC_IP>:~/.kube/config \
  ~/.kube/config-k8s-cluster

KUBECONFIG=~/.kube/config-k8s-cluster kubectl get nodes
```

## Manual Cluster Verification

### On Master Node

```bash
# Check control plane components
sudo kubectl get pods -n kube-system

# Check cluster info
sudo kubectl cluster-info

# Check nodes
sudo kubectl get nodes -o wide

# Wait for nodes to be Ready (may take 5-10 minutes)
watch -n 5 sudo kubectl get nodes
```

### Typical Initialization Timeline

- T+0min: EC2 instances launched
- T+2min: Cloud-init begins software installation
- T+3min: Docker installed and started
- T+4min: kubelet service started
- T+5min: Master kubeadm init begins
- T+6min: Master ready, CNI plugin deployment starts
- T+8min: Worker joins master
- T+10min: All components ready

## Troubleshooting Quick Steps

### Master node not initializing
```bash
ssh -i ~/.ssh/key.pem ubuntu@<MASTER_IP>
sudo tail -100 /var/log/cloud-init-output.log
sudo systemctl status kubelet
```

### Worker not joining
```bash
# Check if master is ready
sudo kubectl get nodes  # From master

# On worker
ssh -i ~/.ssh/key.pem ubuntu@<WORKER_IP>
sudo journalctl -u kubelet -n 50
```

### Networking issues
```bash
# From worker, test connectivity to master
nc -zv <MASTER_PRIVATE_IP> 6443
nslookup kubernetes.default
```

## Next Steps

1. **Deploy Sample Application**
   ```bash
   kubectl create deployment nginx --image=nginx
   kubectl expose deployment nginx --type=LoadBalancer --port=80
   ```

2. **Install Additional CNI Plugins**
   - Flannel (lightweight)
   - Weave (mesh networking)
   - Cilium (advanced observability)

3. **Set up Monitoring**
   - Prometheus for metrics
   - Grafana for visualization
   - ELK stack for logging

4. **Scale to Multiple Workers**
   - Duplicate worker module in `main.tf`
   - Update `terraform.tfvars`
   - Run `terraform apply` again

5. **Implement Persistent Storage**
   - AWS EBS volumes
   - AWS EFS for shared storage
   - StorageClass configuration

6. **Enable Ingress**
   - Install nginx-ingress
   - Configure DNS
   - Set up TLS certificates

## Cleanup

```bash
# Destroy all infrastructure
terraform destroy

# Confirm destruction
# Type 'yes' when prompted

# Clean temporary files
rm -rf .terraform tfplan .terraform.lock.hcl
```

## Cost Optimization

- **Use Spot Instances** for worker nodes (save 70%)
- **Use Smaller Instance Types** for development
- **Set up Auto-scaling** to scale down during off-hours
- **Monitor with AWS Cost Explorer** for usage

## Production Considerations

- [ ] Enable remote state storage (S3 + DynamoDB)
- [ ] Implement RBAC for Kubernetes access control
- [ ] Set up audit logging
- [ ] Enable encryption for Kubernetes secrets
- [ ] Configure network policies
- [ ] Set up regular backups
- [ ] Implement resource quotas
- [ ] Configure pod security policies
- [ ] Set up monitoring and alerting
- [ ] Document runbooks for common operations

## Support and Documentation

- **Terraform Docs**: See [README.md](README.md)
- **AWS Terraform Provider**: https://registry.terraform.io/providers/hashicorp/aws/latest
- **Kubernetes Setup**: https://kubernetes.io/docs/setup/
- **kubeadm Documentation**: https://kubernetes.io/docs/reference/setup-tools/kubeadm/

## Common Commands Reference

```bash
# Terraform
terraform init              # Initialize working directory
terraform plan              # Show changes
terraform apply             # Apply changes
terraform destroy           # Destroy infrastructure
terraform output            # Show outputs
terraform refresh           # Refresh state
terraform state list        # List state resources

# Kubernetes (on master or with remote kubeconfig)
kubectl get nodes           # List nodes
kubectl get pods -A         # List all pods
kubectl describe node NAME  # Node details
kubectl logs POD -n NS      # Pod logs
kubectl exec -it POD -n NS -- bash  # Pod shell

# SSH
ssh -i ~/.ssh/key.pem ubuntu@IP  # Connect to instance
scp -i ~/.ssh/key.pem FILE ubuntu@IP:~  # Copy file

# AWS CLI
aws ec2 describe-instances  # List EC2 instances
aws ec2 describe-key-pairs  # List key pairs
aws ec2 create-key-pair --key-name NAME  # Create key pair
```

Happy Kubernetes clustering! 🚀
