#!/bin/bash
set -e
set -x

# Update system packages
apt-get update
apt-get upgrade -y

# Install required packages
apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    htop \
    git \
    wget \
    net-tools \
    jq \
    unzip

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
chmod +x get-docker.sh
./get-docker.sh
rm get-docker.sh

# Start and enable Docker
systemctl start docker
systemctl enable docker

# Add user to docker group
usermod -aG docker ubuntu 2>/dev/null || true

# Install Kubernetes components
curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://packages.cloud.google.com/apt kubernetes-focal main" | tee /etc/apt/sources.list.d/kubernetes.list

apt-get update
apt-get install -y \
    kubelet=${kubernetes_version}-00 \
    kubeadm=${kubernetes_version}-00 \
    kubectl=${kubernetes_version}-00

# Prevent automatic updates
apt-mark hold kubelet kubeadm kubectl

# Enable kubelet service
systemctl start kubelet
systemctl enable kubelet

# Configure sysctl for Kubernetes
cat >> /etc/sysctl.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF

sysctl -p

# Disable swap
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

# Configure Docker daemon
mkdir -p /etc/docker
cat > /etc/docker/daemon.json <<EOF
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "100m"
  },
  "storage-driver": "overlay2"
}
EOF

systemctl daemon-reload
systemctl restart docker

echo "Bootstrap complete"
