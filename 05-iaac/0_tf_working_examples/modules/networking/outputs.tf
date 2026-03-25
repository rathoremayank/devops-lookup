output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "vpc_cidr" {
  description = "VPC CIDR block"
  value       = aws_vpc.main.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "master_security_group_id" {
  description = "Security group ID for Kubernetes master"
  value       = aws_security_group.master.id
}

output "worker_security_group_id" {
  description = "Security group ID for Kubernetes workers"
  value       = aws_security_group.worker.id
}

output "internet_gateway_id" {
  description = "Internet Gateway ID"
  value       = aws_internet_gateway.main.id
}

