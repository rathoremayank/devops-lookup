output "user_data_script" {
  description = "User data script for initializing Kubernetes node"
  value       = local.user_data_script
  sensitive   = false
}

output "kubernetes_version" {
  description = "Kubernetes version"
  value       = var.kubernetes_version
}

output "node_type" {
  description = "Node type (master or worker)"
  value       = var.node_type
}
