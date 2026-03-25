variable "node_name" {
  description = "Name of the Kubernetes node"
  type        = string
}

variable "node_type" {
  description = "Type of the node (master or worker)"
  type        = string
  validation {
    condition     = contains(["master", "worker"], var.node_type)
    error_message = "node_type must be either 'master' or 'worker'."
  }
}

variable "master_internal_ip" {
  description = "Internal IP address of the Kubernetes master"
  type        = string
  default     = ""
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

variable "docker_version" {
  description = "Docker version to install"
  type        = string
  default     = "24.0.0"
}

variable "service_subnet" {
  description = "Subnet CIDR for Kubernetes services"
  type        = string
  default     = "10.96.0.0/12"
}

variable "tags" {
  description = "Common tags for all resources"
  type        = map(string)
  default     = {}
}
