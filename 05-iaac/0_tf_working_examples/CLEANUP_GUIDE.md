# Cleanup Guide - Remote State Backend Removal

## ⚠️ WARNING

This guide covers **permanently deleting** your Terraform remote state infrastructure. This action:

- ❌ **CANNOT BE UNDONE**
- ❌ Deletes all Terraform state history
- ❌ Removes state locking mechanism
- ✅ Creates automatic backup (saved to `./state-backups/`)

**Only proceed if you:**
- No longer need the remote state
- Have migrated to a different backend
- Are decommissioning the cluster
- Have backed up important infrastructure

---

## When Should You Clean Up?

### Good Reasons to Clean Up
- ✅ Decommissioning the Kubernetes cluster
- ✅ Migrating to a different backend
- ✅ Migrating to a different AWS account
- ✅ Cleaning up after testing/development
- ✅ Consolidating multiple projects

### Bad Reasons (Don't Do This!)
- ❌ Thinking it will save money (minimal cost anyway)
- ❌ Confused about how it works
- ❌ Accidentally selected delete
- ❌ Without backing up first

---

## Before You Clean Up: Checklist

- [ ] Backup your Terraform code in Git
- [ ] Export current infrastructure state
- [ ] Destroy Kubernetes infrastructure with `terraform destroy`
- [ ] Ensure no infrastructure is running
- [ ] Notify team members
- [ ] Verify you have AWS console access
- [ ] Confirm the bucket and table names
- [ ] Have a recovery plan if things go wrong

---

## Backup Procedures

### Manual Backup (Recommended Before Cleanup)

#### Backup Terraform State
```bash
# Linux/macOS
mkdir -p backups
aws s3 sync s3://terraform-state-dev backups/state-dev-$(date +%Y%m%d)

# Windows PowerShell
New-Item -ItemType Directory -Path "backups" -Force
aws s3 sync s3://terraform-state-dev backups/state-dev-$(Get-Date -Format 'yyyyMMdd')
```

#### Backup Terraform Files
```bash
# Linux/macOS
tar -czf backups/terraform-config-$(date +%Y%m%d).tar.gz environments/

# Windows PowerShell
Compress-Archive -Path environments/* -DestinationPath "backups/terraform-config-$(Get-Date -Format 'yyyyMMdd').zip"
```

#### Export DynamoDB Locks
```bash
# List all locks for record
aws dynamodb scan --table-name terraform-locks --region us-east-1
```

### Automatic Backup (Cleanup Scripts)

The cleanup scripts automatically create backups:
```
./state-backups/
  ├─ state-backup-20240325-143022.zip
  ├─ state-backup-20240325-150015.zip
  └─ ...
```

These are automatically created but you should still do manual backups.

---

## Step-by-Step Cleanup

### Understanding What Will Be Deleted

#### S3 Bucket Contents
```
terraform-state-dev/
├─ k8s-cluster/dev/terraform.tfstate           [DELETED]
├─ k8s-cluster/dev/terraform.tfstate.backup    [DELETED]
└─ (all versions in history)                   [DELETED]
```

#### DynamoDB Table Contents
```
terraform-locks
├─ Lock entries for all operations             [DELETED]
├─ Lock history                                [DELETED]
└─ (backup data if enabled)                    [DELETED]
```

### Cleanup Process: Linux/macOS

```bash
# Step 1: Navigate to project
cd 05-iaac/0_tf_working_examples

# Step 2: Run cleanup script (interactive confirmation)
bash scripts/cleanup-remote-state.sh terraform-state-dev

# Step 3: Review what will be deleted
# Script shows:
# - Bucket name
# - Bucket size
# - DynamoDB table name
# - Warning message

# Step 4: Type 'yes' to confirm
# Type: yes

# Step 5: Wait for deletion
# Script will:
# - Create backup
# - Delete S3 objects
# - Delete S3 bucket
# - Delete DynamoDB table
# - Verify deletion

# Step 6: Review results
# Script shows:
# - Deleted resources
# - Backup file location
# - What to clean up locally
```

### Cleanup Process: Windows PowerShell

```powershell
# Step 1: Navigate to project
cd 05-iaac\0_tf_working_examples

# Step 2: Run cleanup script (interactive confirmation)
.\scripts\cleanup-remote-state.ps1 -BucketName "terraform-state-dev"

# Step 3: Review what will be deleted
# Script shows:
# - Bucket name
# - Bucket size
# - DynamoDB table name
# - Colorized warning message

# Step 4: Type 'yes' to confirm
# Type: yes

# Step 5: Wait for deletion
# Script will:
# - Create backup to state-backups/ folder
# - Delete S3 objects and versions
# - Delete S3 bucket
# - Delete DynamoDB table
# - Verify deletion

# Step 6: Review results
# Script displays:
# - Summary of deleted resources
# - Backup file location
# - Next steps
```

### Force Cleanup (No Confirmation)

**⚠️ Use Only If You're Sure!**

```bash
# Linux/macOS (force delete without confirmation)
bash scripts/cleanup-remote-state.sh terraform-state-dev terraform-locks us-east-1 true

# Windows PowerShell (force delete without confirmation)
.\scripts\cleanup-remote-state.ps1 -BucketName "terraform-state-dev" -Force
```

---

## After Cleanup: Local Cleanup

After deleting the remote backend, clean up local files:

### Linux/macOS
```bash
# Remove Terraform cache
cd environments/dev
rm -rf .terraform
rm -f .terraform.lock.hcl

# Remove local state files (if not needed)
rm -f terraform.tfstate*

# Go back to root
cd ../..
```

### Windows PowerShell
```powershell
# Remove Terraform cache
cd environments\dev
Remove-Item -Path .terraform -Recurse -Force
Remove-Item -Path .terraform.lock.hcl -Force

# Remove local state files (if not needed)
Remove-Item -Path terraform.tfstate* -Force

# Go back to root
cd ..\..
```

---

## Post-Cleanup: Reconfigure Terraform

If you want to use Terraform again:

### Reconfigure Local Backend
```bash
# cd environments/dev
rm -f .terraform/terraform.tfstate

# Reinitialize with local backend
terraform init

# Now terraform uses local state
```

### Migrate to New Backend
```bash
# Setup new backend infrastructure
bash scripts/setup-remote-state.sh

# Edit backend config
nano environments/dev/backend-dev.tfbackend

# Migrate state
terraform init -backend-config=backend-dev.tfbackend
```

---

## Troubleshooting Cleanup

### Issue: "Bucket not empty"

**Cause**: S3 versioning enabled and cleanup couldn't remove all versions

**Solution**: Manually delete remaining versions
```bash
aws s3api delete-object --bucket terraform-state-dev --key k8s-cluster/dev/terraform.tfstate
aws s3api delete-bucket --bucket terraform-state-dev
```

### Issue: "DynamoDB table in use"

**Cause**: Recent operations may still have active locks

**Solution**: Wait a minute and try again
```bash
# Wait for locks to expire
sleep 60

# Force cleanup
bash scripts/cleanup-remote-state.sh terraform-state-dev terraform-locks us-east-1 true
```

### Issue: "Access Denied"

**Cause**: IAM permissions insufficient

**Solution**: Verify you have permissions for:
```
s3:DeleteBucket
s3:DeleteObject
s3:DeleteObjectVersion
dynamodb:DeleteTable
```

### Issue: Cleanup script stuck

**Cause**: Long-running operations or network issues

**Solution**: Manual cleanup via AWS CLI
```bash
# List S3 versions
aws s3api list-object-versions --bucket terraform-state-dev

# Delete manually
aws s3 rb s3://terraform-state-dev --force

# Delete DynamoDB table
aws dynamodb delete-table --table-name terraform-locks
```

---

## Recovery: Restoring from Backup

If you need to recover deleted state:

### From State Backup
```bash
# Extract backup
unzip state-backups/state-backup-20240325-143022.zip

# List contents
ls -la state-backup/

# Restore S3 bucket (manual)
# 1. Create new bucket
# 2. Create new backend config
# 3. Restore files to new bucket
```

### From Git History
```bash
# Terraform files are in Git
git log --oneline environments/

# Recover specific file
git show HEAD~5:environments/dev/main.tf
```

### Manual Recovery (Last Resort)
```bash
# From local .terraform directory
cat .terraform/terraform.tfstate

# From system backups
ls -la ~/.terraform/

# From cloud snapshots (if enabled)
aws s3api list-object-versions --bucket terraform-state-dev
```

---

## Cost Implications After Cleanup

### What Stops Costing

After cleanup, these resources are removed:
- S3 bucket storage: **$0/month** (no more costs)
- S3 API requests: **$0/month** (no more costs)
- DynamoDB table: **$0/month** (on-demand billing stops)
- S3 versioning: **$0/month** (no more versions)

### What Still Costs

These continue regardless of backend cleanup:
- EC2 instances (if still running) - **$50+/month**
- VPC endpoints (if any) - **$7+/month**
- Elastic IPs (if still allocated) - **$3+/month**

**Note**: Cleanup saves ~$5-10/month in backend costs. To save significantly, run `terraform destroy` to remove infrastructure.

---

## Verification: Confirming Deletion

### Verify S3 Bucket Deleted
```bash
# Should show NoSuchBucket error
aws s3 ls s3://terraform-state-dev --region us-east-1

# Or check in AWS Console
# S3 → Buckets → Search for bucket name (should not appear)
```

### Verify DynamoDB Table Deleted
```bash
# Should show ResourceNotFoundException
aws dynamodb describe-table --table-name terraform-locks --region us-east-1

# Or check in AWS Console
# DynamoDB → Tables → Search for table name (should not appear)
```

### Verify State Backup Created
```bash
# Check backups directory
ls -la state-backups/

# Verify backup is not corrupted
unzip -t state-backups/state-backup-*.zip
```

---

## Best Practices

### Before Any Cleanup

1. **Notify Team Members**
   - Announce cleanup scheduled time
   - Stop all terraform operations 
   - Get approval from infrastructure leads

2. **Create Comprehensive Backups**
   - Terraform code in Git
   - State files downloaded
   - Screenshots of current infrastructure

3. **Test Recovery Plan**
   - Can you restore from backup?
   - Do backups contain needed data?
   - Is recovery documentation current?

4. **Plan for Downtime**
   - When will cleanup happen?
   - How long will it take? (~5 minutes)
   - Who needs to be available?

### During Cleanup

1. **No Other Operations**
   - Stop terraform apply/destroy
   - Wait for locks to clear
   - Review confirmation carefully

2. **Monitor Deletion**
   - Watch script output
   - Check AWS console in parallel
   - Keep backup logs

3. **Verify Completion**
   - Check backup was created
   - Confirm resources deleted
   - Review cleanup report

### After Cleanup

1. **Document Changes**
   - Update runbooks
   - Document what was deleted
   - Record date/time of cleanup
   - Note team members involved

2. **Monitor Infrastructure**
   - Terraform no longer manages state
   - Manual infrastructure management required
   - Infrastructure will drift if left alone

3. **Plan Next Steps**
   - Will you use Terraform again?
   - Migrate to new backend?
   - Switch to IaC alternative?

---

## Questions?

- **How do I recover if I deleted by mistake?** See "Recovery: Restoring from Backup" section above
- **Will this affect running infrastructure?** No, only state management stops
- **What if cleanup fails halfway?** State backup is created, but manual cleanup may be needed
- **Can I partially delete?** Yes, you can delete bucket without table or vice versa (not recommended)
- **How long does cleanup take?** Usually 2-5 minutes depending on state size

---

## Related Documentation

- [BACKEND_SETUP.md](BACKEND_SETUP.md) - Setting up remote state
- [REMOTE_STATE_SETUP.md](REMOTE_STATE_SETUP.md) - Quick reference
- [scripts/README.md](scripts/README.md) - Script documentation

---

**Proceed with cleanup only when ready!**

Remember: **This cannot be undone. Verify all backups exist before proceeding.**
