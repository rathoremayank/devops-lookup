output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.main.id
}

output "instance_private_ip" {
  description = "Private IP address of the instance"
  value       = aws_instance.main.private_ip
}

output "instance_public_ip" {
  description = "Public IP address of the instance"
  value       = aws_eip.instance.public_ip
}

output "instance_dns" {
  description = "DNS name of the instance"
  value       = aws_instance.main.public_dns
}

output "security_group_id" {
  description = "Security group ID attached to the instance"
  value       = tolist(aws_instance.main.vpc_security_group_ids)[0]
}
