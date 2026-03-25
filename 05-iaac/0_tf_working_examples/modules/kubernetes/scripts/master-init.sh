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

echo "Kubernetes master initialization complete"
