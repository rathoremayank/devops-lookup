variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_name" {
  description = "Name for the EC2 instance"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID where instance will be launched"
  type        = string
}

variable "security_group_id" {
  description = "Security group ID for the instance"
  type        = string
}

variable "key_pair_name" {
  description = "EC2 Key Pair name for SSH access"
  type        = string
}

variable "user_data" {
  description = "User data script for instance initialization"
  type        = string
  default     = ""
}

variable "root_volume_size" {
  description = "Root volume size in GB"
  type        = number
  default     = 30
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "project_name" {
  description = "Project name for resource tagging"
  type        = string
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
