# Remote State Backend Setup Guide

## Overview

This guide walks you through setting up AWS S3 for Terraform remote state management.

## Why Remote State?

- **Collaboration**: Multiple team members can work on the same infrastructure
- **Safety**: State is versioned and backed up automatically
- **Locking**: Prevents concurrent operations from corrupting state
- **Encryption**: State files are encrypted in transit and at rest
- **Auditability**: Track who made changes and when

## Architecture

```
Your Local Machine
        ↓
   terraform apply
        ↓
   AWS API
        ↓
    ┌───────────────────────────┐
    │  S3 Bucket                │
    │  └─ terraform.tfstate    │  ← State file (versioned & encrypted)
    │  └─ terraform.tfstate.backup
    │  └─ version history       │
    │  └─ Versioning manages    │
    │     concurrent locks      │
    └───────────────────────────┘
```

**Note**: S3 versioning provides state management. For distributed locking in high-concurrency environments, consider S3 Object Lock or adding DynamoDB separately.

## Step-by-Step Setup

### Step 1: Prerequisites

```bash
# Verify AWS CLI is installed and configured
aws --version
aws configure  # If not already configured

# Verify Terraform is installed
terraform --version  # Should be >= 1.0

# Get your AWS account ID (you'll need this)
aws sts get-caller-identity --query Account --output text
# Output: 123456789012
```

### Step 2: Create S3 Bucket

**Option A: Using the Setup Script (Recommended)**

```bash
cd 05-iaac/0_tf_working_examples

# Run the setup script
bash scripts/setup-remote-state.sh

# Optional parameters (with defaults):
# bash scripts/setup-remote-state.sh <bucket-name> <region>

# Example:
bash scripts/setup-remote-state.sh \
    terraform-state-my-project \
    us-east-1
```

The script will:
- ✅ Create S3 bucket
- ✅ Enable versioning on S3 bucket
- ✅ Enable encryption on S3 bucket
- ✅ Block all public access
- ✅ Display configuration details

**Option B: Manual Setup**

If you prefer to set up manually, run these commands:

```bash
# Set variables
BUCKET_NAME="terraform-state-dev-$(date +%s)"
TABLE_NAME="terraform-locks"
REGION="us-east-1"

# Create S3 bucket
aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"

# Enable versioning
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'

# Block public access
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true"
```

### Step 3: Configure Backend Configuration File

Edit `environments/dev/backend-dev.tfbackend`:

```hcl
# backend-dev.tfbackend

bucket         = "terraform-state-dev-1234567890"
key            = "k8s-cluster/dev/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
```

**Important**: Replace the values with your actual S3 bucket name.

### Step 4: Initialize Terraform with Remote Backend

```bash
cd environments/dev

# Option A: Using backend config file (Recommended)
terraform init -backend-config=backend-dev.tfbackend

# Option B: Using command-line flags
terraform init \
    -backend-config="bucket=terraform-state-dev-xyz" \
    -backend-config="key=k8s-cluster/dev/terraform.tfstate" \
    -backend-config="region=us-east-1" \
    -backend-config="encrypt=true"
```

### Step 5: Verify Remote State Configuration

```bash
# Check that state is in S3
aws s3 ls s3://terraform-state-dev-xyz/k8s-cluster/dev/

# View Terraform backend status
terraform get -update
terraform state list  # This should now pull from S3
```

## Working with Remote State

### Viewing Remote State

```bash
# List all resources in state
terraform state list

# Show specific resource details
terraform state show aws_vpc.main

# Show entire state (be careful with sensitive data)
terraform state show
```

### State Locking in Action

State locking is managed by S3 versioning:

```bash
# Terminal 1: Run long-running apply
terraform apply

# Terminal 2: Try to apply at same time
terraform apply
# S3 versioning helps manage concurrent operations
```

Note: For advanced distributed locking in high-concurrency scenarios, you can optionally add DynamoDB or enable S3 Object Lock.

## Multiple Environments

### Setup Production Environment

```bash
# Create prod backend
cp -r environments/dev environments/prod

# Create prod backend configuration
cat > environments/prod/backend-prod.tfbackend <<EOF
bucket         = "terraform-state-prod-xyz"
key            = "k8s-cluster/prod/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
EOF

# Initialize prod with separate backend
cd environments/prod
terraform init -backend-config=backend-prod.tfbackend

# Verify separate state
terraform state list  # Different state from dev
```

### Key-Based Environment Separation

States are separated by the S3 `key` path:
- Dev: `k8s-cluster/dev/terraform.tfstate`
- Prod: `k8s-cluster/prod/terraform.tfstate`
- Staging: `k8s-cluster/staging/terraform.tfstate`

## State Management Best Practices

### 1. Version Control

```bash
# S3 versioning is automatically enabled
# View all versions of state file
aws s3api list-object-versions \
    --bucket terraform-state-dev-xyz \
    --prefix "k8s-cluster/dev/"
```

### 2. Encryption

State files contain sensitive information (RDS passwords, SSH keys, etc.):

```bash
# Verify encryption
aws s3api get-bucket-encryption \
    --bucket terraform-state-dev-xyz

# All state files are encrypted with AES-256
```

### 3. Access Control

```bash
# Create bucket policy to restrict access
cat > bucket-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Deny",
            "Principal": "*",
            "Action": "s3:*",
            "Resource": [
                "arn:aws:s3:::terraform-state-dev-xyz",
                "arn:aws:s3:::terraform-state-dev-xyz/*"
            ],
            "Condition": {
                "Bool": {
                    "aws:SecureTransport": "false"
                }
            }
        }
    ]
}
EOF

# Apply policy
aws s3api put-bucket-policy \
    --bucket terraform-state-dev-xyz \
    --policy file://bucket-policy.json
```

### 4. Backup and Recovery

```bash
# Enable MFA delete protection (requires root user)
# This prevents anyone from deleting the state file
# Note: DynamoDB is no longer used in this configuration - see advanced options if needed

# Check S3 versioning status
aws s3api get-bucket-versioning --bucket terraform-state-dev-xyz
```

### 5. Monitoring

```bash
# Check S3 bucket size
aws s3 ls --summarize --human-readable \
    s3://terraform-state-dev-xyz/

# Watch for state file changes
aws s3api list-object-versions \
    --bucket terraform-state-dev-xyz \
    --prefix "k8s-cluster/dev/" \
    --query 'Versions[-1]'

# Enable CloudTrail for audit logging
# All state file access is logged
```

## Troubleshooting

### Problem: "Error: error reading remote state"

```bash
# Check backend configuration
terraform backend show

# Verify S3 bucket exists
aws s3 ls | grep terraform-state

# Check IAM permissions
aws s3api head-bucket --bucket terraform-state-dev-xyz
```

### Problem: "Failed to acquire state lock"

```bash
# S3 versioning manages state conflicts
# Verify S3 versioning is enabled
aws s3api get-bucket-versioning --bucket terraform-state-dev-xyz

# For distributed locking in high-concurrency scenarios,
# consider adding DynamoDB or enabling S3 Object Lock
```

### Problem: "InvalidBucketName"

```bash
# S3 bucket names must be:
# - 3-63 characters long
# - Lowercase letters, numbers, hyphens only
# - Not start/end with hyphen
# - Not be an IP address format

# Fix: Use a valid bucket name
BUCKET_NAME="terraform-state-$(date +%s)"
```

### Problem: "State lock not being released"

```bash
# Check if process is still running
ps aux | grep terraform

# Kill stuck terraform process
kill -9 <pid>

# Wait a few seconds, then manually unlock
terraform force-unlock <lock-id>
```

## Migration: Local to Remote State

If you already have local state, migrate it to remote:

```bash
# 1. Backup local state
cp terraform.tfstate terraform.tfstate.backup

# 2. Set up remote backend as above

# 3. Initialize with remote backend
terraform init -backend-config=backend-dev.tfbackend

# 4. Terraform will detect local state and offer to copy it
# Type 'yes' to proceed

# 5. Verify migration
terraform state list  # Should show your resources
```

## Cost Estimation

```
S3 Bucket:
  - Storage: ~0.023 per GB/month (negligible for state files)
  - Request: ~0.0004 per 1000 PUT/POST/DELETE (minimal)
  
DynamoDB (On-Demand):
  - Read: ~0.25 per million units
  - Write: ~1.25 per million units
  - (Minimal cost for state locking)

Versioning & Encryption: No additional cost

Total monthly cost: ~$0-5 (virtually free)
```

## Security Recommendations

✅ **Do:**
- Enable S3 versioning
- Enable S3 encryption
- Enable S3 object lock (for immutability)
- Use separate buckets per environment
- Enable MFA delete protection
- Enable CloudTrail logging
- Restrict IAM permissions
- Use AWS KMS keys (instead of AES-256) for sensitive environments
- Enable S3 Object Lock for immutability (optional)

❌ **Don't:**
- Share AWS credentials in code
- Store state files in Git
- Make S3 bucket public
- Use weak IAM policies
- Mix dev and prod state files

## Advanced: Custom KMS Encryption

For additional security, use AWS KMS:

```bash
# Create KMS key
KMS_KEY_ID=$(aws kms create-key --description "Terraform state encryption" \
    --query 'KeyMetadata.KeyId' --output text)

# Update backend config
cat > backend-dev.tfbackend <<EOF
bucket         = "terraform-state-dev-xyz"
key            = "k8s-cluster/dev/terraform.tfstate"
region         = "us-east-1"
encrypt        = true
kms_key_id     = "arn:aws:kms:us-east-1:123456789012:key/$KMS_KEY_ID"
EOF

# Re-initialize
terraform init -backend-config=backend-dev.tfbackend
```

## Reference Commands

```bash
# Backend setup
bash scripts/setup-remote-state.sh

# Terraform initialization with backend
terraform init -backend-config=backend-dev.tfbackend

# Work with state
terraform state list
terraform state show <resource>
terraform state push
terraform state pull
terraform state rm <resource>

# Locking
terraform force-unlock <lock-id>

# View backend configuration
terraform backend show

# Reconfigure backend
terraform init -reconfigure -backend-config=backend-dev.tfbackend

# Migrate to different backend
terraform init -migrate-state -backend-config=new-backend.tfbackend
```

## Support and Documentation

- [Terraform S3 Backend Docs](https://www.terraform.io/language/settings/backends/s3)
- [AWS S3 Documentation](https://docs.aws.amazon.com/s3/)
- [AWS DynamoDB Documentation](https://docs.aws.amazon.com/dynamodb/)
- [Terraform State Management](https://www.terraform.io/language/state)

---

**Ready to activate remote state?** Start with Step 2 above!
