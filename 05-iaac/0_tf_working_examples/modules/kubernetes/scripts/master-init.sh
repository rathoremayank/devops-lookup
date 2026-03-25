#!/bin/bash
set -e
set -x

# Wait for system to stabilize
sleep 30

# Initialize Kubernetes master
kubeadm init \
  --pod-network-cidr=${pod_network_cidr} \
  --service-cidr=${service_subnet} \
  --apiserver-advertise-address=$(hostname -I | awk '{print $1}') \
  --token-ttl=0

# Setup kubeconfig
mkdir -p $HOME/.kube
cp /etc/kubernetes/admin.conf $HOME/.kube/config
chown $(id -u):$(id -g) $HOME/.kube/config

# Setup kubeconfig for root
mkdir -p /root/.kube
cp /etc/kubernetes/admin.conf /root/.kube/config

# Copy kubeconfig to /tmp for easy access via EC2 Instance Connect or data retrieval
cp /etc/kubernetes/admin.conf /tmp/kubeconfig
chmod 644 /tmp/kubeconfig

# Setup kubectl bash completion for ubuntu user
mkdir -p /home/ubuntu/.bash_completion.d
kubectl completion bash > /home/ubuntu/.bash_completion.d/kubectl
cat >> /home/ubuntu/.bashrc <<'BASHRC_EOF'
# kubectl completion
if [ -f ~/.bash_completion.d/kubectl ]; then
    source ~/.bash_completion.d/kubectl
fi
export KUBECONFIG=$HOME/.kube/config
BASHRC_EOF

# Setup kubectl bash completion for root
mkdir -p /root/.bash_completion.d
kubectl completion bash > /root/.bash_completion.d/kubectl
cat >> /root/.bashrc <<'BASHRC_EOF'
# kubectl completion
if [ -f ~/.bash_completion.d/kubectl ]; then
    source ~/.bash_completion.d/kubectl
fi
export KUBECONFIG=/root/.kube/config
BASHRC_EOF

# Install CNI (Calico)
kubectl apply -f https://raw.githubusercontent.com/projectcalico/calico/v3.26.1/manifests/tigera-operator.yaml

# Wait for tigera operator
sleep 30

# Create Calico installation
cat <<EOF | kubectl apply -f -
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
EOF

# Wait for Calico to be ready
kubectl wait --for=condition=ready pod -l k8s-app=calico-node -n calico-system --timeout=300s 2>/dev/null || true

# Generate join token for workers
TOKEN=$(kubeadm token create --ttl=24h)
DISCOVERY=$(kubeadm token generate)

# Store token and certificate hash for workers
CERT_HASH=$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')
MASTER_IP=$(hostname -I | awk '{print $1}')

cat > /root/kubeadm-join-command.txt <<EOF
kubeadm join $${MASTER_IP}:6443 --token $${TOKEN} --discovery-token-ca-cert-hash sha256:$${CERT_HASH}
EOF

# Create summary file with cluster information
cat > /tmp/k8s-cluster-info.txt <<INFO_EOF
Kubernetes Cluster Information
==============================
Initialized: \$(date)
Master IP: \$(hostname -I | awk '{print \$1}')
Kubernetes Version: ${kubernetes_version}
Pod Network CIDR: ${pod_network_cidr}

Accessing the Cluster:
1. kubeconfig location: /root/.kube/config (on master node)
2. Copy kubeconfig: /tmp/kubeconfig (readable version)
3. kubectl commands should work automatically after login

To retrieve kubeconfig from local machine:
  scp -i /path/to/key.pem ubuntu@<MASTER_IP>:/tmp/kubeconfig ~/.kube/config

To verify cluster:
  kubectl get nodes
  kubectl get pods --all-namespaces
  kubectl cluster-info

Worker Join Command:
  \$(cat /root/kubeadm-join-command.txt)
INFO_EOF

echo "Kubernetes master initialization complete"
echo "Check /tmp/k8s-cluster-info.txt for cluster information"
