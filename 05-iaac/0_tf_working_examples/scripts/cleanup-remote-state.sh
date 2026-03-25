#!/bin/bash
# Script to clean up AWS S3 bucket used for Terraform remote state (S3-only, no DynamoDB)
# WARNING: This permanently deletes the state backend and cannot be undone!

set -e

# Configuration
BUCKET_NAME="${1:-}"
REGION="${2:-us-east-1}"
FORCE_DELETE="${3:-false}"

# Color codes
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
print_warning() {
    echo -e "${RED}⚠️  WARNING: $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ Error: $1${NC}"
}

# Check if bucket name is provided
if [ -z "$BUCKET_NAME" ]; then
    echo "================================================"
    echo "Terraform Remote State Backend Cleanup"
    echo "================================================"
    echo ""
    print_error "Bucket name is required"
    echo ""
    echo "Usage: bash cleanup-remote-state.sh <bucket-name> [region] [force]"
    echo ""
    echo "Examples:"
    echo "  # Safe mode (interactive confirmation)"
    echo "  bash cleanup-remote-state.sh terraform-state-dev"
    echo ""
    echo "  # With custom region"
    echo "  bash cleanup-remote-state.sh terraform-state-dev us-east-1"
    echo ""
    echo "  bash cleanup-remote-state.sh terraform-state-dev terraform-locks us-east-1 true"
    echo ""
    echo "WARNING: This will permanently delete:"
    echo "  - S3 bucket and ALL its contents"
    echo "  - This cannot be undone!"
    echo ""
    exit 1
fi

echo "================================================"
echo "Terraform Remote State Backend Cleanup"
echo "================================================"
echo ""
print_warning "THIS WILL PERMANENTLY DELETE:"
print_warning "✗ S3 bucket: $BUCKET_NAME"
print_warning "✗ All versions and objects in the bucket"
echo ""
print_warning "THIS ACTION CANNOT BE UNDONE!"
echo ""

# Check if bucket exists
if ! aws s3 ls "s3://$BUCKET_NAME" --region "$REGION" 2>&1 | grep -q "NoSuchBucket"; then
    BUCKET_EXISTS="true"
    BUCKET_SIZE=$(aws s3 ls "s3://$BUCKET_NAME" --recursive --summarize --region "$REGION" | grep "Total Size:" | awk '{print $3}')
    echo "Bucket size: $(numfmt --to=iec-i --suffix=B $BUCKET_SIZE 2>/dev/null || echo "$BUCKET_SIZE bytes")"
else
    BUCKET_EXISTS="false"
    echo "Bucket does not exist (already deleted?)"
fi

echo ""

# Confirmation
if [ "$FORCE_DELETE" != "true" ]; then
    echo "Do you want to proceed with deletion? Type 'yes' to confirm:"
    read -r CONFIRMATION
    
    if [ "$CONFIRMATION" != "yes" ]; then
        echo ""
        print_info "Deletion cancelled"
        exit 0
    fi
fi

echo ""
echo "Proceeding with deletion..."
echo ""

# Create backup of current state (optional but recommended)
if [ "$BUCKET_EXISTS" = "true" ]; then
    print_info "Creating backup of state file..."
    mkdir -p ./state-backups
    BACKUP_FILE="./state-backups/state-backup-$(date +%Y%m%d-%H%M%S).tgz"
    
    aws s3 sync "s3://$BUCKET_NAME" ./state-backup --region "$REGION" 2>/dev/null || true
    tar -czf "$BACKUP_FILE" ./state-backup 2>/dev/null || true
    rm -rf ./state-backup
    
    if [ -f "$BACKUP_FILE" ]; then
        print_success "Backup created: $BACKUP_FILE"
    fi
    echo ""
fi

# Delete S3 bucket
if [ "$BUCKET_EXISTS" = "true" ]; then
    print_info "Deleting S3 bucket: $BUCKET_NAME"
    
    # First, delete all versions (if versioning is enabled)
    print_info "Removing all object versions..."
    aws s3api delete-objects \
        --bucket "$BUCKET_NAME" \
        --delete "$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --region "$REGION" --query='join(`Tombstone=false,`,[Versions||[],DeleteMarkers||[]])|[].{Key:Key,VersionId:VersionId}' --output json | jq -c '.[]')" \
        --region "$REGION" 2>/dev/null || true
    
    # Delete delete markers
    print_info "Removing delete markers..."
    aws s3api delete-objects \
        --bucket "$BUCKET_NAME" \
        --delete "$(aws s3api list-object-versions --bucket "$BUCKET_NAME" --region "$REGION" --query='join(`Tombstone=true,`,[Versions||[],DeleteMarkers||[]])|[].{Key:Key,VersionId:VersionId}' --output json | jq -c '.[]')" \
        --region "$REGION" 2>/dev/null || true
    
    # Delete bucket
    print_info "Removing S3 bucket..."
    aws s3 rb "s3://$BUCKET_NAME" --force --region "$REGION" 2>/dev/null || \
    aws s3api delete-bucket --bucket "$BUCKET_NAME" --region "$REGION" 2>/dev/null || true
    
    # Verify deletion
    sleep 2
    if aws s3 ls "s3://$BUCKET_NAME" --region "$REGION" 2>&1 | grep -q "NoSuchBucket"; then
        print_success "S3 bucket deleted: $BUCKET_NAME"
    else
        print_warning "S3 bucket may still exist, retrying..."
        aws s3 rb "s3://$BUCKET_NAME" --force --region "$REGION" 2>/dev/null || true
        sleep 2
    fi
else
    print_warning "S3 bucket not found, skipping..."
fi

echo ""
echo "================================================"
print_success "Cleanup Complete!"
echo "================================================"
echo ""
echo "Deleted resources:"
echo "  ✗ S3 bucket: $BUCKET_NAME"
echo ""

if [ -f "$BACKUP_FILE" ]; then
    echo "State backup saved to: $BACKUP_FILE"
    echo ""
fi

print_warning "Any local terraform.tfstate files are STILL present"
print_warning "You may want to remove:"
echo "  - terraform.tfstate"
echo "  - terraform.tfstate.backup"
echo "  - .terraform/terraform.tfstate"
echo ""

print_info "Next steps:"
echo "  1. Remove local state files if desired"
echo "  2. Run 'rm -rf .terraform' to remove local backend cache"
echo "  3. Update Terraform configurations to use new backend"
echo "  4. Run 'terraform init' to reconfigure"
echo ""
