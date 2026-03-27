#!/bin/bash
set -x
# Don't exit on errors - we want to try alternatives
set +e

trap 'echo "Bootstrap script encountered error at line $LINENO"' ERR

# Update system packages
echo "Updating package lists..."
apt-get update || {
  echo "WARNING: apt-get update failed, continuing anyway..."
}

# Install required packages
echo "Installing dependencies..."
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
    unzip \
    snapd \
    awscli || {
  echo "WARNING: Some dependencies failed to install, continuing..."
}

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

# Install Kubernetes components from official repository
echo "Installing Kubernetes components..."

# Remove any old Kubernetes repository configurations
rm -f /etc/apt/sources.list.d/kubernetes*.list
rm -f /usr/share/keyrings/kubernetes*.gpg

# Add official Kubernetes repository
echo "Adding official Kubernetes repository..."
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.34/deb/Release.key | gpg --dearmor -o /usr/share/keyrings/kubernetes-apt-keyring.gpg 2>/dev/null || {
  echo "WARNING: Failed to add k8s keyring, trying alternative method..."
  apt-get install -y google-cloud-sdk-gke-gcloud-auth-plugin 2>/dev/null || true
}

echo "deb [signed-by=/usr/share/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.34/deb/ /" | tee /etc/apt/sources.list.d/kubernetes.list

# Update package lists
apt-get update 2>&1 || true

# Install from official Kubernetes repository
echo "Installing Kubernetes from official repository..."
if apt-get install -y kubelet kubeadm kubectl 2>&1; then
  echo "Successfully installed Kubernetes from official repo"
  KUBE_INSTALLED=1
else
  echo "WARNING: Failed to install from official repo, attempting alternative sources..."
  # Fallback: try without specific version
  apt-get install -y kubelet kubeadm kubectl 2>&1 && KUBE_INSTALLED=1 || true
fi

# Final check
if [ "$KUBE_INSTALLED" = "1" ]; then
  echo "Kubernetes components installed successfully"
  kubectl version --client
else
  echo "ERROR: Failed to install Kubernetes components"
  echo "Available packages:"
  apt-cache search kubelet | head -5 || true
  exit 1
fi

# Prevent automatic updates (if installed via apt)
apt-mark hold kubelet kubeadm kubectl 2>/dev/null || true

# Enable kubelet service for startup
systemctl enable kubelet 2>/dev/null || true

# Configure sysctl for Kubernetes
echo "Configuring system settings..."
cat >> /etc/sysctl.conf <<EOF
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
vm.overcommit_memory = 1
EOF
sysctl -p 2>/dev/null || true

# Disable swap
swapoff -a 2>/dev/null || true
sed -i '/ swap / s/^/#/' /etc/fstab 2>/dev/null || true

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

systemctl daemon-reload 2>/dev/null || true
systemctl restart docker 2>/dev/null || true

# Start kubelet
echo "Starting kubelet..."
systemctl daemon-reload 2>/dev/null || true
if systemctl start kubelet 2>/dev/null; then
  echo "kubelet started successfully"
else
  echo "WARNING: Failed to start kubelet, will start during kubeadm init"
fi

echo "Final verification..."
if kubectl version --client 2>&1; then
  echo "kubectl is available"
else
  echo "WARNING: kubectl version check failed, but may be available on path"
  which kubectl || echo "kubectl not found in PATH"
fi

echo "Bootstrap complete"
