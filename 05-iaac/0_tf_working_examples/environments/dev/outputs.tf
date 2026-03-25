output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = module.networking.vpc_cidr
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = module.networking.public_subnet_ids
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.networking.private_subnet_ids
}

output "master_instance_id" {
  description = "Kubernetes master instance ID"
  value       = module.master_instance.instance_id
}

output "master_private_ip" {
  description = "Kubernetes master private IP"
  value       = module.master_instance.instance_private_ip
}

output "master_public_ip" {
  description = "Kubernetes master public IP (Elastic IP)"
  value       = module.master_instance.instance_public_ip
}

output "master_dns" {
  description = "Kubernetes master DNS name"
  value       = module.master_instance.instance_dns
}

output "worker_instance_id" {
  description = "Kubernetes worker instance ID"
  value       = module.worker_instance.instance_id
}

output "worker_private_ip" {
  description = "Kubernetes worker private IP"
  value       = module.worker_instance.instance_private_ip
}

output "worker_public_ip" {
  description = "Kubernetes worker public IP (Elastic IP)"
  value       = module.worker_instance.instance_public_ip
}

output "worker_dns" {
  description = "Kubernetes worker DNS name"
  value       = module.worker_instance.instance_dns
}

output "master_security_group_id" {
  description = "Master security group ID"
  value       = module.networking.master_security_group_id
}

output "worker_security_group_id" {
  description = "Worker security group ID"
  value       = module.networking.worker_security_group_id
}

output "nat_gateway_ips" {
  description = "NAT Gateway Elastic IPs"
  value       = module.networking.nat_gateway_ips
}

output "kubernetes_version" {
  description = "Kubernetes version deployed"
  value       = var.kubernetes_version
}

output "pod_network_cidr" {
  description = "Pod network CIDR"
  value       = var.pod_network_cidr
}

output "ssh_master_command" {
  description = "SSH command to connect to master"
  value       = "ssh -i /path/to/key.pem ubuntu@${module.master_instance.instance_public_ip}"
}

output "ssh_worker_command" {
  description = "SSH command to connect to worker"
  value       = "ssh -i /path/to/key.pem ubuntu@${module.worker_instance.instance_public_ip}"
}
