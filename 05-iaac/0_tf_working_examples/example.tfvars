# Example Terraform Variables
# Copy this file to terraform.tfvars and customize for your environment

aws_region           = "us-east-1"
environment          = "dev"
project_name         = "k8s-cluster"

# Network Configuration
vpc_cidr             = "10.0.0.0/16"
public_subnet_cidrs  = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnet_cidrs = ["10.0.10.0/24", "10.0.11.0/24"]

# EC2 Configuration
# Options:
#   t3.micro (1 vCPU, 1GB) - Not recommended for Kubernetes
#   t3.small (2 vCPU, 2GB)
#   t3.medium (2 vCPU, 4GB)
#   t3.large (2 vCPU, 8GB)
#   t3a.small (2 vCPU, 2GB) - AMD, cheaper alternative
#   t3a.medium (2 vCPU, 4GB)
master_instance_type  = "t3.medium"
worker_instance_type  = "t3.small"

# Kubernetes Configuration
kubernetes_version = "1.28.0"
pod_network_cidr   = "192.168.0.0/16"

# EC2 Key Pair (MUST EXIST in your AWS account)
# Create with: aws ec2 create-key-pair --key-name my-key-pair --query 'KeyMaterial' --output text > ~/.ssh/my-key-pair.pem
ec2_key_pair_name = "my-key-pair"

# Tags for cost tracking and resource management
tags = {
  Owner       = "DevOps-Team"
  CostCenter  = "Engineering"
  BackupPolicy = "daily"
  Environment = "development"
}
