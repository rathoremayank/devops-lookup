# PowerShell Script to clean up AWS S3 bucket used for Terraform remote state (S3-only, no DynamoDB)
# WARNING: This permanently deletes the state backend and cannot be undone!
# Usage: .\cleanup-remote-state.ps1 -BucketName "terraform-state-dev" -Region "us-east-1" [-Force]

param(
    [string]$BucketName = "",
    [string]$Region = "us-east-1",
    [switch]$Force = $false
)

$ErrorActionPreference = "Continue"

# Color codes
function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  WARNING: $Message" -ForegroundColor Red
}

function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([string]$Message)
    Write-Host "✓ $Message" -ForegroundColor Green
}

function Write-Error {
    param([string]$Message)
    Write-Host "✗ Error: $Message" -ForegroundColor Red
}

# Check if bucket name is provided
if ([string]::IsNullOrEmpty($BucketName)) {
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host "Terraform Remote State Backend Cleanup" -ForegroundColor Cyan
    Write-Host "================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Error "Bucket name is required"
    Write-Host ""
    Write-Host "Usage: .\\cleanup-remote-state.ps1 -BucketName <bucket-name> [-Region <region>] [-Force]" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Examples:" -ForegroundColor Yellow
    Write-Host "  # Safe mode (interactive confirmation)"
    Write-Host "  .\cleanup-remote-state.ps1 -BucketName terraform-state-dev" -ForegroundColor White
    Write-Host ""
    Write-Host "  # With custom table name"
    Write-Host "  .\cleanup-remote-state.ps1 -BucketName terraform-state-dev -TableName my-locks -Region us-east-1" -ForegroundColor White
    Write-Host ""
    Write-Host "  # Force delete (no confirmation)"
    Write-Host "  .\cleanup-remote-state.ps1 -BucketName terraform-state-dev -Force" -ForegroundColor White
    Write-Host ""
    Write-Host "WARNING: This will permanently delete:" -ForegroundColor Red
    Write-Host "  - S3 bucket and ALL its contents" -ForegroundColor Red
    Write-Host "  - This cannot be undone!" -ForegroundColor Red
    Write-Host ""
    exit 1
}

Write-Host "================================================" -ForegroundColor Cyan
Write-Host "Terraform Remote State Backend Cleanup" -ForegroundColor Cyan
Write-Host "================================================" -ForegroundColor Cyan
Write-Host ""

Write-Warning "THIS WILL PERMANENTLY DELETE:"
Write-Warning "✗ S3 bucket: $BucketName"
Write-Warning "✗ All versions and objects in the bucket"
Write-Host ""
Write-Warning "THIS ACTION CANNOT BE UNDONE!"
Write-Host ""

# Check if bucket exists
Write-Info "Checking S3 bucket: $BucketName"
try {
    $BucketExists = aws s3api head-bucket --bucket $BucketName --region $Region 2>&1
    if ($LASTEXITCODE -eq 0) {
        $BucketExists = $true
        
        # Get bucket size
        try {
            $BucketInfo = aws s3api list-objects-v2 --bucket $BucketName --region $Region --summarize 2>&1 | Out-String
            if ($BucketInfo -match "Total Size: (\d+)") {
                $BucketSize = [long]$matches[1]
                $FormattedSize = if ($BucketSize -gt 1GB) { 
                    "{0:N2} GB" -f ($BucketSize / 1GB)
                } elseif ($BucketSize -gt 1MB) {
                    "{0:N2} MB" -f ($BucketSize / 1MB)
                } else {
                    "{0:N2} KB" -f ($BucketSize / 1KB)
                }
                Write-Host "Bucket size: $FormattedSize"
            }
        } catch {
            Write-Host "Could not determine bucket size"
        }
    } else {
        $BucketExists = $false
        Write-Host "Bucket does not exist (already deleted?)" -ForegroundColor Yellow
    }
} catch {
    $BucketExists = $false
    Write-Host "Bucket does not exist (already deleted?)" -ForegroundColor Yellow
}

# Check if table exists
Write-Info "Checking DynamoDB table: $TableName"
try {
    $TableStatus = aws dynamodb describe-table --table-name $TableName --region $Region 2>&1
    if ($LASTEXITCODE -eq 0) {
        $TableExists = $true
        Write-Host "DynamoDB table exists: $TableName" -ForegroundColor Yellow
    } else {
        $TableExists = $false
        Write-Host "DynamoDB table does not exist (already deleted?)" -ForegroundColor Yellow
    }
} catch {
    $TableExists = $false
    Write-Host "DynamoDB table does not exist (already deleted?)" -ForegroundColor Yellow
}

Write-Host ""

# Confirmation
if (-not $Force) {
    Write-Host "Do you want to proceed with deletion?" -ForegroundColor Red
    Write-Host "Type 'yes' to confirm: " -NoNewline -ForegroundColor Yellow
    $Confirmation = Read-Host
    
    if ($Confirmation -ne "yes") {
        Write-Host ""
        Write-Info "Deletion cancelled"
        exit 0
    }
}

Write-Host ""
Write-Host "Proceeding with deletion..." -ForegroundColor Yellow
Write-Host ""

# Create backup of current state (optional but recommended)
if ($BucketExists) {
    Write-Info "Creating backup of state file..."
    
    if (-not (Test-Path "./state-backups")) {
        New-Item -ItemType Directory -Path "./state-backups" -Force | Out-Null
    }
    
    $BackupFile = "./state-backups/state-backup-$(Get-Date -Format 'yyyyMMdd-HHmmss').zip"
    
    try {
        # Create temp directory for backup
        $TempBackupDir = New-Item -ItemType Directory -Path "./state-backup-temp" -Force
        
        # Sync S3 contents
        aws s3 sync "s3://$BucketName" "$($TempBackupDir.FullName)" --region $Region 2>&1 | Out-Null
        
        # Zip the contents
        if (Test-Path "$($TempBackupDir.FullName)") {
            Compress-Archive -Path "$($TempBackupDir.FullName)/*" -DestinationPath $BackupFile -Force
            Remove-Item $TempBackupDir -Recurse -Force
            
            if (Test-Path $BackupFile) {
                Write-Success "Backup created: $BackupFile"
            }
        }
    } catch {
        Write-Host "Warning: Could not create backup - $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Delete S3 bucket
if ($BucketExists) {
    Write-Info "Deleting S3 bucket: $BucketName"
    
    try {
        # List and delete all object versions
        Write-Info "Removing all object versions..."
        $Versions = aws s3api list-object-versions `
            --bucket $BucketName `
            --region $Region `
            --query 'Versions[*].[Key,VersionId]' `
            --output json 2>&1 | ConvertFrom-Json
        
        if ($Versions) {
            foreach ($Version in $Versions) {
                aws s3api delete-object `
                    --bucket $BucketName `
                    --key $Version[0] `
                    --version-id $Version[1] `
                    --region $Region 2>&1 | Out-Null
            }
        }
        
        # Delete bucket
        Write-Info "Removing S3 bucket..."
        aws s3 rb "s3://$BucketName" --force --region $Region 2>&1 | Out-Null
        
        # Verify deletion
        Start-Sleep -Seconds 2
        $BucketStillExists = aws s3api head-bucket --bucket $BucketName --region $Region 2>&1
        
        if ($LASTEXITCODE -ne 0) {
            Write-Success "S3 bucket deleted: $BucketName"
        } else {
            Write-Warning "S3 bucket may still exist, retrying..."
            aws s3 rb "s3://$BucketName" --force --region $Region 2>&1 | Out-Null
            Start-Sleep -Seconds 2
        }
    } catch {
        Write-Warning "Error deleting S3 bucket: $($_.Exception.Message)"
    }
} else {
    Write-Warning "S3 bucket not found, skipping..."
}

Write-Host ""
Write-Host "================================================" -ForegroundColor Green
Write-Success "Cleanup Complete!"
Write-Host "================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Deleted resources:" -ForegroundColor White
Write-Host "  ✗ S3 bucket: $BucketName" -ForegroundColor White
Write-Host ""

if (Test-Path $BackupFile) {
    Write-Host "State backup saved to: $BackupFile" -ForegroundColor Yellow
    Write-Host ""
}

Write-Warning "Any local terraform.tfstate files are STILL present"
Write-Warning "You may want to remove:"
Write-Host "  - terraform.tfstate" -ForegroundColor White
Write-Host "  - terraform.tfstate.backup" -ForegroundColor White
Write-Host "  - .terraform/terraform.tfstate" -ForegroundColor White
Write-Host ""

Write-Info "Next steps:"
Write-Host "  1. Remove local state files if desired" -ForegroundColor White
Write-Host "  2. Run 'Remove-Item -Path .terraform -Recurse' to remove local backend cache" -ForegroundColor White
Write-Host "  3. Update Terraform configurations to use new backend" -ForegroundColor White
Write-Host "  4. Run 'terraform init' to reconfigure" -ForegroundColor White
Write-Host ""
