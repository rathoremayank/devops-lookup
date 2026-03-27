#!/bin/bash
set -x

echo "========================================="
echo "Kubernetes Master Fix Script"
echo "========================================="

# Check if kubeadm init actually ran
if [ ! -f /etc/kubernetes/admin.conf ]; then
  echo "ERROR: /etc/kubernetes/admin.conf does not exist"
  echo "kubeadm init did not complete successfully"
  echo "Checking logs..."
  sudo tail -n 50 /var/log/k8s-master-init.log
  exit 1
fi

echo "✓ /etc/kubernetes/admin.conf exists"

# Setup kubeconfig for root user
echo "Setting up root kubeconfig..."
sudo mkdir -p /root/.kube
sudo cp /etc/kubernetes/admin.conf /root/.kube/config
sudo chmod 600 /root/.kube/config
echo "✓ Root kubeconfig set up"

# Setup kubeconfig for ubuntu user
echo "Setting up ubuntu user kubeconfig..."
mkdir -p ~/.kube
sudo cp /etc/kubernetes/admin.conf ~/.kube/config
sudo chown ubuntu:ubuntu ~/.kube/config
sudo chmod 600 ~/.kube/config
echo "✓ Ubuntu user kubeconfig set up"

# Copy to /tmp for reference
sudo cp /etc/kubernetes/admin.conf /tmp/kubeconfig
sudo chmod 644 /tmp/kubeconfig
echo "✓ kubeconfig copied to /tmp/kubeconfig"

# Set KUBECONFIG environment variable
export KUBECONFIG=~/.kube/config
echo "✓ KUBECONFIG environment variable set"

# Wait for API server to be ready
echo "Waiting for Kubernetes API server to respond..."
MAX_ATTEMPTS=30
ATTEMPT=0
while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  if kubectl get nodes &>/dev/null 2>&1; then
    echo "✓ API server is responding"
    break
  fi
  echo "  Attempt $((ATTEMPT+1))/$MAX_ATTEMPTS - API server not ready yet..."
  sleep 2
  ATTEMPT=$((ATTEMPT+1))
done

if [ $ATTEMPT -ge $MAX_ATTEMPTS ]; then
  echo "ERROR: API server did not respond after ${MAX_ATTEMPTS} attempts"
  echo "Checking kubelet status..."
  sudo systemctl status kubelet || echo "kubelet service not found"
  echo "Checking for control plane pods..."
  kubectl get pods -n kube-system 2>/dev/null || echo "Cannot list pods - API server not ready"
  exit 1
fi

# Test kubectl commands
echo ""
echo "========================================="
echo "Testing kubectl commands..."
echo "========================================="

echo ""
echo "1. kubectl get nodes:"
kubectl get nodes

echo ""
echo "2. kubectl cluster-info:"
kubectl cluster-info

echo ""
echo "3. kubectl get pods -n kube-system:"
kubectl get pods -n kube-system

echo ""
echo "========================================="
echo "✓ Master node fixed successfully!"
echo "========================================="
echo ""
echo "Next steps:"
echo "1. Verify workers can join with: kubectl get nodes"
echo "2. Check worker status: kubectl describe node <worker-name>"
echo "3. Monitor pods: kubectl get pods --all-namespaces"
