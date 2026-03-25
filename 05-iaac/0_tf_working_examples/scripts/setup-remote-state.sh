#!/bin/bash
# Script to set up AWS S3 bucket for Terraform remote state (S3-only, no DynamoDB)
# Run this ONCE before initializing Terraform

set -e

# Configuration
BUCKET_NAME="${1:-terraform-state-$(date +%s)}"
REGION="${2:-us-east-1}"
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

echo "================================================"
echo "Terraform Remote State Backend Setup (S3 Only)"
echo "================================================"
echo "Bucket Name: $BUCKET_NAME"
echo "Region: $REGION"
echo "AWS Account: $ACCOUNT_ID"
echo "================================================"
echo ""

# Check if bucket exists
if aws s3 ls "s3://$BUCKET_NAME" 2>&1 | grep -q 'NoSuchBucket'; then
    echo "Creating S3 bucket: $BUCKET_NAME"
    aws s3 mb "s3://$BUCKET_NAME" --region "$REGION"
else
    echo "S3 bucket already exists: $BUCKET_NAME"
fi

# Enable versioning
echo "Enabling versioning on S3 bucket..."
aws s3api put-bucket-versioning \
    --bucket "$BUCKET_NAME" \
    --versioning-configuration Status=Enabled \
    --region "$REGION"

# Enable encryption
echo "Enabling default encryption on S3 bucket..."
aws s3api put-bucket-encryption \
    --bucket "$BUCKET_NAME" \
    --server-side-encryption-configuration '{
        "Rules": [
            {
                "ApplyServerSideEncryptionByDefault": {
                    "SSEAlgorithm": "AES256"
                }
            }
        ]
    }' \
    --region "$REGION"

# Block public access
echo "Blocking public access to S3 bucket..."
aws s3api put-public-access-block \
    --bucket "$BUCKET_NAME" \
    --public-access-block-configuration \
    "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" \
    --region "$REGION"

# Enable S3 Object Lock (optional - for immutability and compliance)
echo "Note: S3 Object Lock can be enabled for additional compliance requirements"
echo "For standard state management, S3 versioning is sufficient for state locking"

# Display results
echo ""
echo "================================================"
echo "✓ Remote State Backend Setup Complete!"
echo "================================================"
echo ""
echo "Update your terraform.tfvars or create backend-dev.tfbackend with:"
echo ""
echo "bucket         = \"$BUCKET_NAME\""
echo "key            = \"terraform.tfstate\""
echo "region         = \"$REGION\""
echo "encrypt        = true"
echo ""
echo "Then run:"
echo "  cd environments/dev"
echo "  terraform init -backend-config=backend-dev.tfbackend"
echo ""
