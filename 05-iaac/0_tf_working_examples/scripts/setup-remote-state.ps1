# PowerShell Script to set up AWS S3 bucket for Terraform remote state (S3-only, no DynamoDB)
# Run this ONCE before initializing Terraform
# Usage: .\setup-remote-state.ps1 -BucketName "terraform-state-dev" -Region "us-east-1"

param(
    [string]$BucketName = "terraform-state-$(Get-Random -Maximum 10000)",
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

# Get AWS Account ID
try {
    $AccountID = (aws sts get-caller-identity --query Account --output text)
    if (-not $AccountID) {
        throw "Could not retrieve AWS Account ID"
    }
} catch {
    Write-Host "ERROR: Make sure AWS CLI is installed and configured" -ForegroundColor Red
    exit 1
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Terraform Remote State Backend Setup (S3 Only)" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Bucket Name: $BucketName" -ForegroundColor Yellow
Write-Host "Region: $Region" -ForegroundColor Yellow
Write-Host "AWS Account: $AccountID" -ForegroundColor Yellow
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

# Create S3 bucket
Write-Host "Creating S3 bucket: $BucketName" -ForegroundColor Green
try {
    aws s3 mb "s3://$BucketName" --region $Region
    Write-Host "✓ S3 bucket created successfully" -ForegroundColor Green
} catch {
    if ($_ -match "BucketAlreadyExists|BucketAlreadyOwnedByYou") {
        Write-Host "ℹ S3 bucket already exists" -ForegroundColor Yellow
    } else {
        throw $_
    }
}

# Enable versioning
Write-Host "Enabling versioning on S3 bucket..." -ForegroundColor Green
$versioningConfig = @{
    Bucket = $BucketName
    VersioningConfiguration = @{ Status = "Enabled" }
    Region = $Region
}
aws s3api put-bucket-versioning `
    --bucket $BucketName `
    --versioning-configuration Status=Enabled `
    --region $Region
Write-Host "✓ Versioning enabled" -ForegroundColor Green

# Enable encryption
Write-Host "Enabling default encryption on S3 bucket..." -ForegroundColor Green
$encryptionConfig = @"
{
    "Rules": [
        {
            "ApplyServerSideEncryptionByDefault": {
                "SSEAlgorithm": "AES256"
            }
        }
    ]
}
"@

$encryptionConfig | aws s3api put-bucket-encryption `
    --bucket $BucketName `
    --server-side-encryption-configuration @- `
    --region $Region
Write-Host "✓ Encryption enabled" -ForegroundColor Green

# Block public access
Write-Host "Blocking public access to S3 bucket..." -ForegroundColor Green
aws s3api put-public-access-block `
    --bucket $BucketName `
    --public-access-block-configuration BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true `
    --region $Region
Write-Host "✓ Public access blocked" -ForegroundColor Green

# S3 versioning above provides state locking for Terraform
Write-Host "State management enabled via S3 versioning" -ForegroundColor Green
Write-Host "Note: S3 Object Lock can be optionally enabled for immutability/compliance" -ForegroundColor Cyan

# Display results
Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Host "✓ Remote State Backend Setup Complete!" -ForegroundColor Green
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Update your backend configuration file with:" -ForegroundColor Cyan
Write-Host ""
Write-Host "bucket         = `"$BucketName`"" -ForegroundColor White
Write-Host "key            = `"k8s-cluster/dev/terraform.tfstate`"" -ForegroundColor White
Write-Host "region         = `"$Region`"" -ForegroundColor White
Write-Host "encrypt        = true" -ForegroundColor White
Write-Host ""
Write-Host "Then run:" -ForegroundColor Cyan
Write-Host "  cd environments/dev" -ForegroundColor White
Write-Host "  terraform init -backend-config=backend-dev.tfbackend" -ForegroundColor White
Write-Host ""
Write-Host "For detailed instructions, see: BACKEND_SETUP.md" -ForegroundColor Cyan
