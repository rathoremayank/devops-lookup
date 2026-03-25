#!/bin/bash
set -x

# Redirect output to log file for debugging
exec > >(tee -a /var/log/k8s-worker-init.log)
exec 2>&1

echo "Starting Kubernetes worker node initialization at $(date)"

# Wait for system and kubelet to stabilize
echo "Waiting for system to stabilize..."
sleep 60

# Verify kubelet is running
echo "Checking if kubelet is running..."
for i in {1..30}; do
  if systemctl is-active --quiet kubelet; then
    echo "Kubelet is running"
    break
  fi
  echo "Waiting for kubelet... ($i/30)"
  sleep 2
done

# Wait for master to be ready
echo "Attempting to connect to master at ${master_internal_ip}:6443..."
MAX_ATTEMPTS=60
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  if timeout 5 curl -s -k https://${master_internal_ip}:6443/version > /dev/null 2>&1; then
    echo "Master is reachable"
    break
  fi
  echo "Waiting for master to be ready... (attempt $((ATTEMPT+1))/$MAX_ATTEMPTS)"
  sleep 5
  ATTEMPT=$((ATTEMPT+1))
done

if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
  echo "ERROR: Master node did not become ready after $((MAX_ATTEMPTS * 5)) seconds"
  echo "Master IP: ${master_internal_ip}"
  echo "Check network connectivity and master node status"
  echo "Logs saved to: /var/log/k8s-worker-init.log"
  exit 1
fi

echo "Master node is ready, attempting to join cluster..."

# Set up environment for kubectl
export KUBECONFIG=/root/.kube/config

# Try to join the cluster
# Note: The join command should be provided as part of the cluster setup
# We'll try multiple strategies

success=false

# Strategy 1: Retrieve join command from SSM Parameter Store
if [ -n "${ssm_parameter_name}" ]; then
  echo "Attempting to retrieve join command from SSM Parameter Store..."
  REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
  
  KUBEADM_JOIN_COMMAND=$(aws ssm get-parameter \
    --name "${ssm_parameter_name}" \
    --query 'Parameter.Value' \
    --output text \
    --region "$${REGION}" \
    2>/dev/null || echo "")
  
  if [ -n "$KUBEADM_JOIN_COMMAND" ] && [ "$KUBEADM_JOIN_COMMAND" != "pending" ]; then
    echo "Found join command in SSM, executing..."
    eval "$KUBEADM_JOIN_COMMAND"
    success=$?
    if [ "$success" == "0" ]; then
      echo "Successfully executed join command from SSM"
    else
      echo "Failed to execute SSM join command, will try alternatives"
    fi
  else
    echo "SSM parameter is empty or pending, trying alternatives..."
  fi
fi

# Strategy 2: Check if join command was provided in environment
if [ "$success" != "0" ] && [ -n "$KUBEADM_JOIN_COMMAND_OVERRIDE" ]; then
  echo "Using KUBEADM_JOIN_COMMAND_OVERRIDE environment variable..."
  eval "$KUBEADM_JOIN_COMMAND_OVERRIDE"
  success=$?
fi

# Strategy 3: If we have a token and cert hash from environment variables, use them
if [ "$success" != "0" ] && [ -n "$KUBEADM_TOKEN" ] && [ -n "$KUBEADM_CERT_HASH" ]; then
  echo "Using provided token and certificate hash..."
  kubeadm join ${master_internal_ip}:6443 \
    --token $KUBEADM_TOKEN \
    --discovery-token-ca-cert-hash sha256:$KUBEADM_CERT_HASH
  success=$?
fi

# Strategy 4: Look for join command file (in case it's available)
if [ "$success" != "0" ] && [ -f /tmp/kubeadm-join-command.txt ]; then
  echo "Found join command file, using it..."
  bash /tmp/kubeadm-join-command.txt
  success=$?
fi

if [ "$success" != "0" ]; then
  echo "ERROR: Failed to join cluster"
  echo "Available attempted strategies:"
  echo "  1. SSM Parameter Store (${ssm_parameter_name})"
  echo "  2. KUBEADM_JOIN_COMMAND_OVERRIDE environment variable"
  echo "  3. KUBEADM_TOKEN and KUBEADM_CERT_HASH environment variables"
  echo "  4. /tmp/kubeadm-join-command.txt file"
  echo ""
  echo "DEBUG INFO:"
  echo "  Master IP: ${master_internal_ip}"
  echo "  SSM Parameter Name: ${ssm_parameter_name}"
  echo "  Kubelet status: $(systemctl is-active kubelet)"
  echo "  Kubelet logs (last 20 lines):"
  journalctl -u kubelet -n 20 --no-pager
  echo ""
  echo "Logs saved to: /var/log/k8s-worker-init.log"
  echo "To manually retrieve join command from SSM:"
  echo "  aws ssm get-parameter --name ${ssm_parameter_name} --query 'Parameter.Value' --output text"
  exit 1
fi

echo "Successfully joined Kubernetes cluster"

# Create info file
cat > /tmp/k8s-worker-info.txt <<INFO_EOF
Kubernetes Worker Node Information
==================================
Initialized: $$(date)
Master IP: ${master_internal_ip}
Kubelet Status: $$(systemctl is-active kubelet)

Logs:
  Worker init logs: /var/log/k8s-worker-init.log
  Kubelet logs: journalctl -u kubelet -n 100

To check if node joined cluster (from master):
  kubectl get nodes
  kubectl describe node $$(hostname)
INFO_EOF

echo "Kubernetes worker node initialization complete at $$(date)"
echo "Check /tmp/k8s-worker-info.txt for node information"
echo "Check /var/log/k8s-worker-init.log for detailed logs"
