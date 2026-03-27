#!/bin/bash
set -x

# Redirect output to log file for debugging (simple redirection for compatibility)
LOG_FILE="/var/log/k8s-master-init.log"
mkdir -p $(dirname $LOG_FILE)
exec 1>> $LOG_FILE
exec 2>> $LOG_FILE

echo "Starting Kubernetes master initialization at $(date)"

# Wait for system and kubelet to stabilize (shorter wait for t2.micro)
echo "Waiting for system to stabilize..."
sleep 15

# Verify kubelet is running (check both systemd and snap)
echo "Checking if kubelet is running..."
for i in {1..30}; do
  if systemctl is-active --quiet kubelet 2>/dev/null; then
    echo "Kubelet is running"
    break
  fi
  echo "Waiting for kubelet... ($i/30)"
  sleep 2
done

# Additional check if systemd service exists
if ! systemctl is-active --quiet kubelet 2>/dev/null; then
  echo "ERROR: kubelet service is not running"
  systemctl status kubelet || true
  exit 1
fi

# Verify Docker or container runtime is running
echo "Checking container runtime..."
docker ps > /dev/null 2>&1 || {
  echo "ERROR: Docker is not running or not available"
  echo "Docker status:"
  systemctl status docker || echo "Docker service not found"
  echo "Available container runtimes:"
  which docker containerd cri-o 2>/dev/null || echo "No container runtime found"
  exit 1
}

# Verify swap is disabled
echo "Checking swap status..."
if [ $(swapon --show | wc -l) -gt 1 ]; then
  echo "ERROR: Swap is still enabled. kubeadm requires swap to be disabled."
  echo "Run: sudo swapoff -a"
  exit 1
fi
echo "Swap is properly disabled"

# Initialize Kubernetes master
echo "Initializing Kubernetes cluster..."
MASTER_IP=$(hostname -I | awk '{print $1}')
echo "Using Master IP: $MASTER_IP"
echo "Pod Network CIDR: ${pod_network_cidr}"
echo "Service CIDR: ${service_subnet}"

kubeadm init \
  --pod-network-cidr=${pod_network_cidr} \
  --service-cidr=${service_subnet} \
  --apiserver-advertise-address=$MASTER_IP \
  --token-ttl=0 2>&1 | tee -a $LOG_FILE || {
  echo "ERROR: kubeadm init failed"
  echo "Debugging info:"
  echo "--- Kubelet status ---"
  systemctl status kubelet || echo "Kubelet not running"
  echo "--- Docker status ---"
  docker ps || echo "Docker error"
  echo "--- System info ---"
  free -m
  cat /proc/cmdline | grep -o 'cgroup[^ ]*' || echo "No cgroup info"
  exit 1
}

echo "Kubernetes cluster initialized successfully"

# Setup kubeconfig immediately for root (cloud-init user) and ubuntu SSH user
echo "Setting up kubeconfig..."

# Root kubeconfig (used during this script and by root user)
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config
chmod 600 /root/.kube/config

# Ubuntu user kubeconfig (for SSH login as ubuntu)
if id ubuntu &>/dev/null; then
  mkdir -p /home/ubuntu/.kube
  cp /etc/kubernetes/admin.conf /home/ubuntu/.kube/config
  chown ubuntu:ubuntu /home/ubuntu/.kube/config
  chmod 600 /home/ubuntu/.kube/config
fi

# Copy kubeconfig to /tmp for easy access
cp /etc/kubernetes/admin.conf /tmp/kubeconfig
chmod 644 /tmp/kubeconfig

# Set KUBECONFIG environment variable so kubectl uses the right credentials
export KUBECONFIG=/root/.kube/config
echo "KUBECONFIG is set to: $KUBECONFIG"
echo "Testing kubeconfig access..."
if kubectl config view --raw > /dev/null 2>&1; then
  echo "kubeconfig is valid and accessible"
else
  echo "ERROR: kubeconfig is not valid"
  ls -la /root/.kube/config
  exit 1
fi

# Wait for API server to be ready
echo "Waiting for Kubernetes API server to be ready..."
for i in {1..60}; do
  if kubectl get nodes &>/dev/null; then
    echo "Kubernetes API server is ready"
    break
  fi
  echo "Waiting for API server... ($i/60)"
  sleep 1
done

# Verify kubeadm worked
echo "Verifying kubectl installation..."
kubectl version --client
kubectl cluster-info || {
  echo "WARNING: kubectl cluster-info failed but may still be initializing"
}

# Install CNI (Calico) - skip if offline, just ensure cluster is ready
echo "Installing Calico CNI (may fail if no internet)..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml 2>/dev/null || {
  echo "WARNING: Calico CNI installation skipped (verify manually if needed)"
}

# Create Calico installation with optimized settings for t2.micro
cat <<'CALICO_EOF' | kubectl apply -f - 2>/dev/null || true
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  calicoNetwork:
    ipPools:
    - blockSize: 26
      cidr: ${pod_network_cidr}
      encapsulation: VXLANCrossSubnet
      natOutgoing: Enabled
      nodeSelector: all()
  nodeMetricsPort: 9091
  typhaMetricsPort: 9093
CALICO_EOF

echo "Calico installation requested (may take time to be ready)"

# Generate join token for workers
echo "Generating worker join token..."
# Ensure API server is fully ready before generating token
MAX_WAIT=60
for attempt in $(seq 1 $MAX_WAIT); do
  if kubectl api-versions &>/dev/null; then
    echo "API server is fully ready for token generation"
    break
  fi
  if [ $attempt -eq $MAX_WAIT ]; then
    echo "WARNING: API server did not fully ready after $MAX_WAIT seconds, attempting token generation anyway"
  fi
  sleep 1
done

TOKEN=$(kubeadm token create --ttl=24h 2>&1) || {
  echo "ERROR: Failed to create kubeadm token"
  echo "Token creation output: $TOKEN"
  exit 1
}
echo "Generated token: $TOKEN"

# Store token and certificate hash for workers
CERT_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt 2>/dev/null | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex 2>/dev/null | sed 's/^.* //')
MASTER_IP=$(hostname -I | awk '{print $1}')

JOIN_COMMAND="kubeadm join $${MASTER_IP}:6443 --token $${TOKEN} --discovery-token-ca-cert-hash sha256:$${CERT_HASH}"

cat > /root/kubeadm-join-command.txt <<JOIN_EOF
$${JOIN_COMMAND}
JOIN_EOF

chmod 644 /root/kubeadm-join-command.txt
cat /root/kubeadm-join-command.txt

# Write join command to SSM Parameter Store
echo "Storing join command in SSM Parameter Store..."
if [ -n "${ssm_parameter_name}" ]; then
  # Get AWS region from EC2 metadata
  REGION=$(curl -s http://169.254.169.254/latest/meta-data/placement/region)
  
  aws ssm put-parameter \
    --name "${ssm_parameter_name}" \
    --value "$${JOIN_COMMAND}" \
    --overwrite \
    --region "$${REGION}" \
    2>/dev/null || {
    echo "WARNING: Failed to store join command in SSM Parameter Store"
    echo "DEBUG: Region=$$REGION, Parameter=${ssm_parameter_name}"
    echo "Make sure EC2 instance has proper IAM permissions for SSM"
  }
else
  echo "WARNING: ssm_parameter_name not provided, skipping SSM storage"
fi

# Create summary file with cluster information
cat > /tmp/k8s-cluster-info.txt <<INFO_EOF
Kubernetes Cluster Information
==============================
Initialized: $$(date)
Master IP: $${MASTER_IP}
Kubernetes Version: ${kubernetes_version}
Pod Network CIDR: ${pod_network_cidr}

Accessing the Cluster:
1. kubeconfig location: /root/.kube/config (on master node)
2. Copy kubeconfig: /tmp/kubeconfig (readable version)
3. kubectl commands should work automatically after login

To retrieve kubeconfig from local machine:
  scp -i /path/to/key.pem ubuntu@$${MASTER_IP}:/tmp/kubeconfig ~/.kube/config

To verify cluster:
  kubectl get nodes
  kubectl get pods --all-namespaces
  kubectl cluster-info

Worker Join Command:
  $$(cat /root/kubeadm-join-command.txt)

Logs:
  Master init logs: /var/log/k8s-master-init.log
  Kubelet logs: journalctl -u kubelet -n 100
INFO_EOF

echo "Kubernetes master initialization complete at $$(date)"
echo "Check /tmp/k8s-cluster-info.txt for cluster information"
echo "Check /var/log/k8s-master-init.log for detailed logs"
