#!/bin/bash
set -x

# Redirect output to log file for debugging
exec > >(tee -a /var/log/k8s-master-init.log)
exec 2>&1

echo "Starting Kubernetes master initialization at $(date)"

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

# Initialize Kubernetes master
echo "Initializing Kubernetes cluster..."
kubeadm init \
  --pod-network-cidr=${pod_network_cidr} \
  --service-cidr=${service_subnet} \
  --apiserver-advertise-address=$(hostname -I | awk '{print $1}') \
  --token-ttl=0 \
  --log-dir=/var/log/kubernetes || {
  echo "ERROR: kubeadm init failed"
  exit 1
}

echo "Kubernetes cluster initialized successfully"

# Setup kubeconfig
echo "Setting up kubeconfig..."
mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config

# Copy kubeconfig to /tmp for easy access
cp /etc/kubernetes/admin.conf /tmp/kubeconfig
chmod 644 /tmp/kubeconfig

# Wait for API server to be ready
echo "Waiting for Kubernetes API server to be ready..."
export KUBECONFIG=/root/.kube/config
for i in {1..60}; do
  if kubectl get nodes &>/dev/null; then
    echo "Kubernetes API server is ready"
    break
  fi
  echo "Waiting for API server... ($i/60)"
  sleep 2
done

# Verify kubeadm is installed and kubectl works
echo "Verifying kubectl installation..."
kubectl version --client
kubectl cluster-info

# Install CNI (Calico) - but don't fail if it doesn't work immediately
echo "Installing Calico CNI..."
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml || {
  echo "WARNING: Failed to apply Calico operator, retrying..."
  sleep 10
  kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml || true
}

# Create Calico installation
sleep 10
cat <<'CALICO_EOF' | kubectl apply -f - || true
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
CALICO_EOF

echo "Calico installation requested (may take time to be ready)"

# Generate join token for workers
echo "Generating worker join token..."
TOKEN=$(kubeadm token create --ttl=24h)

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
