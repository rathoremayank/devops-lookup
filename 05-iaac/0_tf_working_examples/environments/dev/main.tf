locals {
  common_tags = merge(
    {
      Environment = var.environment
      Project     = var.project_name
      ManagedBy   = "Terraform"
      CreatedAt   = timestamp()
    },
    var.tags
  )

  availability_zones = data.aws_availability_zones.available.names
  ssm_parameter_name = "/${var.project_name}/${var.environment}/kubeadm-join-command"
}

# Get available AZs
data "aws_availability_zones" "available" {
  state = "available"
}

# Get latest Ubuntu 22.04 LTS AMI
data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "state"
    values = ["available"]
  }
}

# Networking Module
module "networking" {
  source = "../../modules/networking"

  vpc_cidr            = var.vpc_cidr
  public_subnet_cidrs = var.public_subnet_cidrs
  availability_zones  = local.availability_zones
  environment         = var.environment
  project_name        = var.project_name
  aws_region          = var.aws_region
  tags                = local.common_tags
}

# Kubernetes Master Module (for user data generation)
module "k8s_master" {
  source = "../../modules/kubernetes"

  node_name              = "${var.project_name}-master"
  node_type              = "master"
  kubernetes_version     = var.kubernetes_version
  pod_network_cidr       = var.pod_network_cidr
  ssm_parameter_name     = local.ssm_parameter_name
  tags                   = local.common_tags
}

# EC2 Instance for Master
module "master_instance" {
  source = "../../modules/ec2"

  instance_name           = "${var.project_name}-master"
  instance_type           = var.master_instance_type
  ami_id                  = data.aws_ami.ubuntu.id
  subnet_id               = module.networking.public_subnet_ids[0]
  security_group_id       = module.networking.master_security_group_id
  iam_instance_profile    = aws_iam_instance_profile.k8s_node_profile.name
  key_pair_name           = var.ec2_key_pair_name
  user_data               = module.k8s_master.user_data_script
  root_volume_size        = 10
  environment             = var.environment
  project_name            = var.project_name
  tags                    = local.common_tags
}

# IAM Role for EC2 instances to access SSM Parameter Store
resource "aws_iam_role" "k8s_node_role" {
  name = "${var.project_name}-k8s-node-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = local.common_tags
}

# IAM Policy for SSM Parameter Store access
resource "aws_iam_role_policy" "k8s_node_ssm_policy" {
  name = "${var.project_name}-k8s-node-ssm-policy"
  role = aws_iam_role.k8s_node_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:PutParameter",
          "ssm:GetParameter",
          "ssm:DeleteParameter"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${data.aws_caller_identity.current.account_id}:parameter${local.ssm_parameter_name}"
      }
    ]
  })
}

# Instance Profile for EC2 instances
resource "aws_iam_instance_profile" "k8s_node_profile" {
  name = "${var.project_name}-k8s-node-profile"
  role = aws_iam_role.k8s_node_role.name

  lifecycle {
    ignore_changes = [tags_all]
  }
}

# Get current AWS account ID
data "aws_caller_identity" "current" {}

# SSM Parameter to store kubeadm join command (initial placeholder)
resource "aws_ssm_parameter" "kubeadm_join_command" {
  name  = local.ssm_parameter_name
  type  = "String"
  value = "pending"

  description = "Kubeadm join command for worker nodes to join the cluster"

  tags = merge(
    local.common_tags,
    {
      Name = "${var.project_name}-kubeadm-join-command"
    }
  )

  lifecycle {
    ignore_changes = [value]
  }
}

# Kubernetes Worker Module (for user data generation)
module "k8s_worker" {
  source = "../../modules/kubernetes"

  node_name              = "${var.project_name}-worker-1"
  node_type              = "worker"
  master_internal_ip     = module.master_instance.instance_private_ip
  kubernetes_version     = var.kubernetes_version
  pod_network_cidr       = var.pod_network_cidr
  ssm_parameter_name     = local.ssm_parameter_name
  tags                   = local.common_tags
}

# EC2 Instance for Worker
module "worker_instance" {
  source = "../../modules/ec2"

  instance_name           = "${var.project_name}-worker-1"
  instance_type           = var.worker_instance_type
  ami_id                  = data.aws_ami.ubuntu.id
  subnet_id               = module.networking.public_subnet_ids[1]
  security_group_id       = module.networking.worker_security_group_id
  iam_instance_profile    = aws_iam_instance_profile.k8s_node_profile.name
  key_pair_name           = var.ec2_key_pair_name
  user_data               = module.k8s_worker.user_data_script
  root_volume_size        = 10
  environment             = var.environment
  project_name            = var.project_name
  tags                    = local.common_tags
}
