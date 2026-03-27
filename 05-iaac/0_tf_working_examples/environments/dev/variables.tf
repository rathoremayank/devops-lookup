variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "ap-south-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource naming and tagging"
  type        = string
  default     = "k8s-cluster"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "ec2_key_pair_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
}

variable "master_instance_type" {
  description = "EC2 instance type for Kubernetes master"
  type        = string
  default     = "t3.micro"
}

variable "worker_instance_type" {
  description = "EC2 instance type for Kubernetes worker"
  type        = string
  default     = "t2.micro"
}

variable "kubernetes_version" {
  description = "Kubernetes version to install"
  type        = string
  default     = "1.28.0"
}

variable "pod_network_cidr" {
  description = "CIDR block for pod network"
  type        = string
  default     = "192.168.0.0/16"
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
