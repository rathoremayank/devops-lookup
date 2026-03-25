# Scripts Directory

Utility scripts for managing the Kubernetes cluster infrastructure.

## Available Scripts

### setup-remote-state.sh
Bootstrap Terraform remote state backend on AWS.

**Purpose**: 
- Create S3 bucket for storing Terraform state
- Create DynamoDB table for state locking
- Configure S3 bucket encryption and versioning
- Enable point-in-time recovery on DynamoDB

**Prerequisites**:
- AWS CLI installed and configured
- AWS credentials with S3, DynamoDB, and IAM permissions

**Usage (Linux/macOS)**:
```bash
# With default names
bash setup-remote-state.sh

# With custom names
bash setup-remote-state.sh \
    my-terraform-state-bucket \
    my-terraform-locks \
    us-east-1

# With environment variables
export AWS_REGION="us-west-2"
bash setup-remote-state.sh
```

**Output**:
- S3 bucket: `terraform-state-<timestamp>`
- DynamoDB table: `terraform-locks`
- Configuration values to use in `backend-dev.tfbackend`

**Next Steps**:
1. Copy the output values
2. Update `environments/dev/backend-dev.tfbackend`
3. Run `terraform init -backend-config=environments/dev/backend-dev.tfbackend`

---

### setup-remote-state.ps1
Bootstrap Terraform remote state backend on AWS (Windows PowerShell).

**Purpose**: Same as bash version, but for Windows users

**Prerequisites**:
- AWS CLI installed and configured
- PowerShell 5.0+ (Windows 10/11 or PowerShell Core)
- AWS credentials with S3, DynamoDB, and IAM permissions

**Usage (Windows PowerShell)**:
```powershell
# Navigate to scripts directory
cd scripts

# With default names
.\setup-remote-state.ps1

# With custom names
.\setup-remote-state.ps1 `
    -BucketName "my-terraform-state" `
    -TableName "my-locks" `
    -Region "us-west-2"
```

**If you get execution policy error**:
```powershell
# Allow script execution (one-time setup)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or run script with bypass
powershell -ExecutionPolicy Bypass -File .\setup-remote-state.ps1
```

**Output**:
- S3 bucket created with versioning and encryption
- DynamoDB table created with on-demand billing
- Configuration template displayed
- Instructions for next steps

---

### cleanup-remote-state.sh
Clean up and delete Terraform remote state backend resources on AWS.

**Purpose**:
- Delete S3 bucket containing Terraform state
- Delete DynamoDB table for state locking
- Create backup of state files before deletion
- Verify complete removal

**DANGER**: This permanently deletes state files and cannot be undone!

**Prerequisites**:
- AWS CLI installed and configured
- AWS credentials with S3 and DynamoDB delete permissions
- Bucket and table names to delete

**Usage (Linux/macOS)**:
```bash
# Safe mode (interactive confirmation)
bash cleanup-remote-state.sh terraform-state-dev

# With custom table name
bash cleanup-remote-state.sh terraform-state-dev my-locks us-east-1

# Force delete (no confirmation)
bash cleanup-remote-state.sh terraform-state-dev terraform-locks us-east-1 true
```

**What it does**:
1. Creates automatic backup of state files (saved to `./state-backups/`)
2. Lists S3 bucket contents and size
3. Prompts for confirmation (unless `-force` used)
4. Removes all S3 objects and versions
5. Deletes S3 bucket
6. Deletes DynamoDB table
7. Verifies deletion completed
8. Shows next steps

**Safety Features**:
- Interactive confirmation by default
- Automatic state backup before deletion
- Clear warnings about data loss
- Verification of deletion completion

---

### cleanup-remote-state.ps1
Clean up and delete Terraform remote state backend resources on AWS (Windows PowerShell).

**Purpose**: Same as bash version, but for Windows users

**Prerequisites**:
- AWS CLI installed and configured
- PowerShell 5.0+ (Windows 10/11 or PowerShell Core)
- AWS credentials with S3 and DynamoDB delete permissions

**Usage (Windows PowerShell)**:
```powershell
# Safe mode (interactive confirmation)
.\cleanup-remote-state.ps1 -BucketName "terraform-state-dev"

# With custom table name and region
.\cleanup-remote-state.ps1 `
    -BucketName "terraform-state-dev" `
    -TableName "my-locks" `
    -Region "us-east-1"

# Force delete (no confirmation)
.\cleanup-remote-state.ps1 -BucketName "terraform-state-dev" -Force
```

**If you get execution policy error**:
```powershell
# Allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or run with bypass
powershell -ExecutionPolicy Bypass -File .\cleanup-remote-state.ps1 -BucketName "terraform-state-dev"
```

**What it does**:
1. Creates automatic backup of state files (saved to `./state-backups/`)
2. Displays bucket size and contents
3. Prompts for confirmation (unless -Force used)
4. Removes all S3 objects and versions
5. Deletes S3 bucket
6. Deletes DynamoDB table
7. Verifies deletion completed
8. Shows next steps

**Safety Features**:
- Interactive confirmation by default (colorized prompts)
- Automatic backup before deletion
- Clear warnings about data loss
- Verification of deletion completion

---

## Quick Start (Windows Users)

```powershell
# 1. Run setup script
.\scripts\setup-remote-state.ps1 -BucketName "terraform-state-dev" -Region "us-east-1"

# 2. Copy output values from the script

# 3. Edit backend configuration
code environments\dev\backend-dev.tfbackend
# Update with values from step 1

# 4. Initialize Terraform
cd environments\dev
terraform init -backend-config=backend-dev.tfbackend

# 5. Verify
terraform state list
```

## Quick Start (Linux/macOS Users)

```bash
# 1. Run setup script
bash scripts/setup-remote-state.sh

# 2. Copy output values from the script

# 3. Edit backend configuration
nano environments/dev/backend-dev.tfbackend
# Update with values from step 1

# 4. Initialize Terraform
cd environments/dev
terraform init -backend-config=backend-dev.tfbackend

# 5. Verify
terraform state list
```

## Cleanup Quick Start

### Windows Users (Remove Backend)
```powershell
# Remove development backend (safe mode with confirmation)
.\scripts\cleanup-remote-state.ps1 -BucketName "terraform-state-dev"

# Or force delete without confirmation
.\scripts\cleanup-remote-state.ps1 -BucketName "terraform-state-dev" -Force

# Then clean up local Terraform cache
Remove-Item -Path environments\dev\.terraform -Recurse -Force
```

### Linux/macOS Users (Remove Backend)
```bash
# Remove development backend (safe mode with confirmation)
bash scripts/cleanup-remote-state.sh terraform-state-dev

# Or force delete without confirmation
bash scripts/cleanup-remote-state.sh terraform-state-dev terraform-locks us-east-1 true

# Then clean up local Terraform cache
rm -rf environments/dev/.terraform
```

**⚠️ WARNING**: Cleanup scripts permanently delete your state storage!
- State backups are automatically created in `./state-backups/`
- Cannot be undone
- Requires confirmation unless `-Force` or `force` used

---

## Script Details

### What setup-remote-state does:

1. **Retrieves AWS Account ID**
   - Used for naming and identification

2. **Creates S3 Bucket**
   - Stores Terraform state files
   - Enables versioning for history
   - Enables encryption (AES-256)
   - Blocks all public access

3. **Configures DynamoDB Table**
   - Enables state locking
   - Prevents concurrent modifications
   - Uses on-demand billing (pay per use)
   - Enables point-in-time recovery

4. **Outputs Configuration**
   - Displays values needed for `backend-*.tfbackend`
   - Shows exact commands to run next

### Error Handling:

The scripts handle common errors gracefully:
- If bucket already exists, it continues
- If table already exists, it continues  
- If feature already enabled, it skips
- Clear error messages for permission issues

### What cleanup-remote-state does:

⚠️ **DESTRUCTIVE OPERATION - USE WITH CAUTION**

1. **Creates State Backup**
   - Automatically downloads all state files
   - Saves to `./state-backups/state-backup-<timestamp>.zip`
   - Allows recovery if needed

2. **Verifies Resources**
   - Checks if S3 bucket exists
   - Checks if DynamoDB table exists
   - Reports bucket size

3. **Requests Confirmation**
   - Shows what will be deleted
   - Requires explicit "yes" confirmation
   - Can be bypassed with `-force` flag

4. **Deletes S3 Bucket**
   - Removes all object versions
   - Removes delete markers (if versioning enabled)
   - Verifies complete deletion

5. **Deletes DynamoDB Table**
   - Removes all lock entries
   - Waits for table to be fully removed
   - Verifies complete deletion

6. **Reports Status**
   - Shows what was deleted
   - Displays backup file location
   - Suggests next cleanup steps

### Safety Features:

- **Automatic backups**: State files saved before deletion
- **Confirmation prompts**: Clear warnings and confirmation required
- **Error recovery**: Handles partial failures gracefully
- **Deletion verification**: Confirms resources were removed
- **Helpful output**: Shows next steps and what to clean up locally

## Configuration Files

### backend-dev.tfbackend
- Development environment backend configuration template
- Should be customized with your S3 bucket and DynamoDB table names
- Not committed to Git (see .gitignore)
- Reference template committed for documentation

### backend-prod.tfbackend
- Production environment backend configuration template
- Should use separate S3 bucket and DynamoDB table
- Not committed to Git (see .gitignore)
- Reference template committed for documentation

## Environment Variables

Both scripts support these AWS environment variables:

```bash
# Linux/macOS
export AWS_REGION="us-east-1"
export AWS_PROFILE="my-profile"

# Windows PowerShell
$env:AWS_REGION = "us-east-1"
$env:AWS_PROFILE = "my-profile"
```

## Troubleshooting

### "AWS CLI not found"
```bash
# Install AWS CLI
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

# Verify
aws --version
```

### "Unable to locate credentials"
```bash
# Configure AWS credentials
aws configure
# Or: aws configure --profile my-profile

# Verify credentials
aws sts get-caller-identity
```

### "AccessDenied when creating bucket"
```
You need AWS permissions for:
- s3:CreateBucket
- s3:PutBucketVersioning
- s3:PutBucketEncryption
- s3:PutPublicAccessBlock
- dynamodb:CreateTable
- dynamodb:UpdateContinuousBackups

Contact your AWS administrator if missing
```

### "ExecutionPolicy" error on Windows
```powershell
# Allow from current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or run with bypass
powershell -ExecutionPolicy Bypass -File .\setup-remote-state.ps1
```

## Custom Automation

### Using in CI/CD Pipeline

```bash
# GitHub Actions
- name: Setup Terraform Backend
  env:
    AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
    AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
  run: bash scripts/setup-remote-state.sh

# GitLab CI
setup_backend:
  script:
    - bash scripts/setup-remote-state.sh
  environment:
    name: development
```

### Using in Makefiles

```makefile
backend-setup:
	@bash scripts/setup-remote-state.sh
	@echo "Update backend config files manually"

backend-setup-prod:
	@bash scripts/setup-remote-state.sh \
		terraform-state-prod \
		terraform-locks-prod \
		us-east-1
```

## Security Recommendations

✅ **Do:**
- Use unique bucket names per AWS account
- Enable versioning (done by script)
- Enable encryption (done by script)
- Use separate buckets for dev/prod
- Enable MFA delete protection (manually)
- Restrict IAM access to bucket/table
- Enable CloudTrail logging
- Monitor S3 bucket access

❌ **Don't:**
- Commit backend config with real bucket names
- Share AWS credentials
- Make bucket public
- Use weak IAM policies
- Skip DynamoDB locking
- Ignore encryption warnings

## Related Documentation

- [BACKEND_SETUP.md](../BACKEND_SETUP.md) - Comprehensive backend setup guide
- [CLEANUP_GUIDE.md](../CLEANUP_GUIDE.md) - **Complete cleanup procedure** (READ BEFORE CLEANUP!)
- [CLEANUP_QUICK_REFERENCE.md](../CLEANUP_QUICK_REFERENCE.md) - Quick reference for cleanup commands
- [README.md](../README.md) - Main project documentation
- [terraform.tfstate documentation](https://www.terraform.io/language/state)

## Support

For issues or questions:
1. Check BACKEND_SETUP.md troubleshooting section
2. Review AWS CloudTrail for API errors
3. Verify IAM permissions
4. Check AWS service status

---

**Ready to set up remote state?** Run the appropriate script for your OS!
