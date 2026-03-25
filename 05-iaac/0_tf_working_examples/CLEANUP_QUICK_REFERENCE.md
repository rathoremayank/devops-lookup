# Cleanup Quick Reference Card

**⚠️ CRITICAL: This PERMANENTLY DELETES your Terraform state. Read [CLEANUP_GUIDE.md](CLEANUP_GUIDE.md) first!**

## Pre-Cleanup Checklist

- [ ] Read [CLEANUP_GUIDE.md](CLEANUP_GUIDE.md) completely
- [ ] Backup Terraform files to Git
- [ ] Destroy infrastructure: `terraform destroy`
- [ ] Verify no resources in AWS
- [ ] Notify team members
- [ ] Manual backup created

---

## Quick Cleanup: Windows PowerShell

```powershell
# Navigate to project root
cd 05-iaac\0_tf_working_examples

# Run cleanup (interactive - you'll type 'yes' to confirm)
.\scripts\cleanup-remote-state.ps1 -BucketName "terraform-state-dev"

# Wait for completion (~2-5 minutes)
# Backup saved to: .\state-backups\state-backup-TIMESTAMP.zip
```

---

## Quick Cleanup: Linux/macOS

```bash
# Navigate to project root
cd 05-iaac/0_tf_working_examples

# Run cleanup (interactive - you'll type 'yes' to confirm)
bash scripts/cleanup-remote-state.sh terraform-state-dev

# Wait for completion (~2-5 minutes)
# Backup saved to: ./state-backups/state-backup-TIMESTAMP.zip
```

---

## Cleanup with Makefile

```bash
# From project root
make backend-clean

# Or if you prefer shorter syntax
make backend-cleanup
```

---

## Force Cleanup (No Confirmation)

**⚠️ Use only if absolutely certain!**

### Windows PowerShell
```powershell
.\scripts\cleanup-remote-state.ps1 -BucketName "terraform-state-dev" -Force
```

### Linux/macOS
```bash
bash scripts/cleanup-remote-state.sh terraform-state-dev terraform-locks us-east-1 true
```

---

## After Cleanup: Local Cleanup

```bash
# Windows PowerShell
cd environments\dev
Remove-Item -Path .terraform -Recurse -Force
Remove-Item -Path .terraform.lock.hcl -Force -ErrorAction SilentlyContinue

# Linux/macOS
cd environments/dev
rm -rf .terraform .terraform.lock.hcl
```

---

## Verify Deletion

### Check S3 Bucket Deleted (Should Error)
```bash
aws s3 ls s3://terraform-state-dev --region us-east-1
```

### Check DynamoDB Table Deleted (Should Error)
```bash
aws dynamodb describe-table --table-name terraform-locks --region us-east-1
```

### Check Backup Created
```bash
# Windows PowerShell
ls .\state-backups

# Linux/macOS
ls -la ./state-backups/
```

---

## If Something Goes Wrong

### Cleanup Failed Halfway
```bash
# Check what still exists
aws s3 ls s3://terraform-state-dev
aws dynamodb list-tables

# Manual cleanup
aws s3 rb s3://terraform-state-dev --force
aws dynamodb delete-table --table-name terraform-locks
```

### Need to Recover?
1. Stop immediately - don't do another cleanup
2. Restore from backup in `state-backups/` directory
3. See [CLEANUP_GUIDE.md#recovery-restoring-from-backup](CLEANUP_GUIDE.md#recovery-restoring-from-backup)
4. Contact team lead if unsure

### Cleanup Stuck?
```bash
# Wait for locks to expire
sleep 60

# Try again with force
# Windows: .\scripts\cleanup-remote-state.ps1 -BucketName "..." -Force
# Linux: bash scripts/cleanup-remote-state.sh ... ... ... true
```

---

## Cleanup Command Parameters

### PowerShell
```powershell
-BucketName "terraform-state-dev"    # Required: S3 bucket name
-TableName "terraform-locks"         # Optional: DynamoDB table (auto-detected)
-Region "us-east-1"                  # Optional: AWS region (default: us-east-1)
-Force                               # Optional: Skip confirmation prompt
```

### Bash
```bash
BucketName                           # Arg 1: Required, S3 bucket name
TableName                            # Arg 2: Optional, DynamoDB table name
Region                               # Arg 3: Optional, AWS region (default: us-east-1)
ForceDelete                          # Arg 4: Optional, "true" to skip confirmation
```

---

## What Gets Deleted

### S3 Bucket (`terraform-state-dev`)
- ❌ All state file versions
- ❌ All version history
- ❌ All delete markers
- ❌ Bucket itself

### DynamoDB Table (`terraform-locks`)
- ❌ All lock entries
- ❌ Lock history
- ❌ Table itself

### What's NOT Deleted
- ✅ Terraform code in Git (safe)
- ✅ Local state files (if any)
- ✅ Backups in `state-backups/` directory
- ✅ Running EC2 instances (run `terraform destroy` first!)

---

## Cost After Cleanup

**Savings:** ~$5-10/month in backend costs
**Still Costs:**
- EC2 instances (if running): $50+/month
- VPC resources: $7+/month

**To save significantly:** Run `terraform destroy` to remove infrastructure.

---

## Common Mistakes (DON'T DO THESE!)

❌ **Don't** cleanup without reading CLEANUP_GUIDE.md
❌ **Don't** cleanup without destroying infrastructure first
❌ **Don't** cleanup without backup
❌ **Don't** cleanup during active terraform operations
❌ **Don't** cleanup if you're not sure what you're doing
❌ **Don't** cleanup if the bucket name is wrong

---

## Next Steps After Cleanup

### If Done with Infrastructure Entirely
```bash
# Local cleanup (remove Terraform cache)
cd environments/dev && rm -rf .terraform .terraform.lock.hcl
```

### If Redeploying with New Backend
```bash
# Setup new backend
bash scripts/setup-remote-state.sh

# Edit backend config
vi environments/dev/backend-dev.tfbackend

# Reinitialize
terraform init -backend-config=backend-dev.tfbackend
```

### If Using Local State Only
```bash
cd environments/dev
terraform init  # Use local state

# Future: terraform init -backend-config=... to add remote state
```

---

## Support

📖 **Full Guide:** [CLEANUP_GUIDE.md](CLEANUP_GUIDE.md)
📖 **Backend Setup:** [BACKEND_SETUP.md](BACKEND_SETUP.md)
📖 **Scripts:** [scripts/README.md](scripts/README.md)

---

**Remember: You cannot undo cleanup. Verify all backups exist first!**

---

## Cleanup Timeline

- **Pre-cleanup:** 5-10 minutes (reading, backup, shutdown)
- **Actual cleanup:** 2-5 minutes (script execution)
- **Post-cleanup:** 2 minutes (verification, local cleanup)
- **Total time:** ~10-15 minutes

---

## Emergency Recovery

If you delete state by mistake:

1. **STOP** - Don't do anything else
2. **BACKUP** - Save everything you have
3. **RESTORE** - Extract backup from `state-backups/state-backup-*.zip`
4. **SETUP** - Recreate backend infrastructure
5. **RECOVER** - Import state from backup
6. **VERIFY** - Run `terraform plan` to check

See [CLEANUP_GUIDE.md#recovery-restoring-from-backup](CLEANUP_GUIDE.md#recovery-restoring-from-backup) for detailed recovery steps.

