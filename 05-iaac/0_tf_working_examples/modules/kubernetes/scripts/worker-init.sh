#!/bin/bash
set -e
set -x

# Wait for system to stabilize
sleep 60

# Wait for master to be ready
MAX_ATTEMPTS=30
ATTEMPT=0

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
  if curl -s -k https://${master_internal_ip}:6443/version > /dev/null 2>&1; then
    echo "Master is ready"
    break
  fi
  echo "Waiting for master... (attempt $((ATTEMPT+1))/$MAX_ATTEMPTS)"
  sleep 10
  ATTEMPT=$((ATTEMPT+1))
done

# Get join command from master
# This assumes the join command is available via a method like EC2 user data or metadata
# In production, you'd want a more robust method like:
# - AWS Secrets Manager
# - S3 bucket
# - SSM Parameter Store

# For this example, we'll generate the join command locally
# In production, fetch this from a secure location

# Alternative: Join with token and discovery token ca cert hash
# These would be passed as variables or retrieved from a secure store

# For now, attempt to join if we have the join command
if [ -f /tmp/kubeadm-join-command.txt ]; then
  bash /tmp/kubeadm-join-command.txt
else
  # Fallback: If no join command available, log error
  echo "Warning: kubeadm join command not found in /tmp/kubeadm-join-command.txt"
  echo "This would normally be provided by the master node or secure configuration store"
  exit 1
fi

echo "Kubernetes worker node initialization complete"
