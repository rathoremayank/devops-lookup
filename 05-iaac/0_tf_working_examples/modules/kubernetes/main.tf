# Local variables for user data scripts
locals {
  common_bootstrap = base64encode(templatefile("${path.module}/scripts/common-bootstrap.sh", {
    kubernetes_version = var.kubernetes_version
    docker_version     = var.docker_version
  }))

  master_init = base64encode(templatefile("${path.module}/scripts/master-init.sh", {
    kubernetes_version = var.kubernetes_version
    pod_network_cidr = var.pod_network_cidr
    service_subnet   = var.service_subnet
    ssm_parameter_name = var.ssm_parameter_name
  }))

  worker_init = base64encode(templatefile("${path.module}/scripts/worker-init.sh", {
    master_internal_ip = var.master_internal_ip
    ssm_parameter_name = var.ssm_parameter_name
  }))
}

# Outputs for the kubernetes module that will be used by EC2 module
locals {
  user_data_script = var.node_type == "master" ? "${templatefile("${path.module}/scripts/common-bootstrap.sh", {
    kubernetes_version = var.kubernetes_version
    docker_version     = var.docker_version
    })}\n${templatefile("${path.module}/scripts/master-init.sh", {
    kubernetes_version = var.kubernetes_version
    pod_network_cidr = var.pod_network_cidr
    service_subnet   = var.service_subnet
    ssm_parameter_name = var.ssm_parameter_name
  })}" : "${templatefile("${path.module}/scripts/common-bootstrap.sh", {
    kubernetes_version = var.kubernetes_version
    docker_version     = var.docker_version
    })}\n${templatefile("${path.module}/scripts/worker-init.sh", {
    master_internal_ip = var.master_internal_ip
    ssm_parameter_name = var.ssm_parameter_name
  })}"
}
