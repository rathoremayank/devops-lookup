# Cleanup Safety Checklist

**Use this checklist before running ANY cleanup operations**

---

## Section 1: Pre-Cleanup Preparation (Complete BEFORE reading further)

- [ ] **Read CLEANUP_GUIDE.md fully** - No exceptions, this is mandatory
- [ ] **Read CLEANUP_QUICK_REFERENCE.md** - Familiarize with commands
- [ ] **Ensure Git branch is clear** - All code committed and pushed
- [ ] **Notify team members** - Announce cleanup window
- [ ] **Scheduled cleanup time** - Not during business hours if possible
- [ ] **Backup location identified** - Know where `state-backups/` will be saved
- [ ] **AWS console accessible** - Can verify deletion afterwards
- [ ] **Credentials verified** - AWS CLI is configured and working

---

## Section 2: Infrastructure Verification (Verify current state)

- [ ] **Kubernetes cluster destroyed** - Run `terraform destroy` first if not done
- [ ] **No running EC2 instances** - Verify instances are terminated
- [ ] **No running containers** - Kubernetes cluster should not exist
- [ ] **No active deployments** - No helm charts or workloads running
- [ ] **No active terraform operations** - No `terraform apply` or `terraform plan` running
- [ ] **Terraform cache cleared** - `.terraform/` directory is not locked

**Verification commands:**
```bash
# Check AWS console or run:
aws ec2 describe-instances --query 'Reservations[].Instances[].{ID:InstanceId,State:State.Name}'

# Should return: no instances or all terminated
```

---

## Section 3: Backup Verification (Confirm backups exist)

- [ ] **Terraform code in Git** - Latest version committed
  ```bash
  git log --oneline -5
  ```

- [ ] **State files downloaded** (optional but recommended)
  ```bash
  # Linux/macOS
  mkdir -p backups
  aws s3 sync s3://terraform-state-dev backups/pre-cleanup-$(date +%Y%m%d)
  
  # Windows PowerShell
  New-Item -ItemType Directory -Path "backups" -Force
  aws s3 sync s3://terraform-state-dev backups/pre-cleanup-$(Get-Date -Format 'yyyyMMdd')
  ```

- [ ] **Backup storage verified** - Have offline storage for backups if needed

- [ ] **Backup integrity checked** - Can successfully list backup contents
  ```bash
  # Linux/macOS
  aws s3 ls s3://terraform-state-dev/
  
  # Windows PowerShell  
  aws s3 ls s3://terraform-state-dev/
  ```

---

## Section 4: Resource Verification (Confirm what will be deleted)

### S3 Bucket Check
```bash
# Verify bucket name is correct
aws s3 ls s3://terraform-state-dev --region us-east-1

# Should show terraform state files like:
# k8s-cluster/dev/terraform.tfstate
# k8s-cluster/dev/terraform.tfstate.backup
```

- [ ] **Bucket name confirmed** - Know exactly which bucket to delete
- [ ] **Bucket contains only state files** - No other critical data
- [ ] **Bucket versioning enabled** - All versions will be deleted
- [ ] **No bucket policies blocking deletion** - Cleanup script can access it

### DynamoDB Table Check
```bash
# Verify table name is correct
aws dynamodb describe-table --table-name terraform-locks --region us-east-1

# Should show table status: ACTIVE
```

- [ ] **Table name confirmed** - Know exactly which table to delete
- [ ] **Table is empty or has only old locks** - No active locks
- [ ] **No active read/write operations** - Table is idle
- [ ] **No backup dependencies** - Table backup not needed

---

## Section 5: Team Sign-Off (Get approval)

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Lead | _____________ | _____________ | _____________ |
| Ops | _____________ | _____________ | _____________ |
| Dev | _____________ | _____________ | _____________ |

**Sign-Off Notes:**
```
_________________________________________________________________

_________________________________________________________________
```

---

## Section 6: Execute Cleanup

### Pre-Execution
- [ ] **Clear desktop** - Clean workspace, no distractions
- [ ] **Have documents ready** - CLEANUP_GUIDE.md, CLEANUP_QUICK_REFERENCE.md open
- [ ] **AWS console open** - S3 and DynamoDB in separate browser tabs
- [ ] **Terminal ready** - PowerShell or bash terminal open
- [ ] **VPN connected** - If corporate network required
- [ ] **MFA enabled** - Have authenticator app ready

### Execution (Choose ONE)

**Option A: Interactive Mode (Recommended)**
```bash
# Windows PowerShell
.\scripts\cleanup-remote-state.ps1 -BucketName "terraform-state-dev"

# Linux/macOS
bash scripts/cleanup-remote-state.sh terraform-state-dev
```

- [ ] **Type 'yes' when prompted** - Do NOT type anything else
- [ ] **Script running** - Watch for progress messages
- [ ] **No errors** - Script completes without errors
- [ ] **Backup created** - Verify backup in `state-backups/` directory

**Option B: Force Mode (Only if you're absolutely sure)**
```bash
# Windows PowerShell
.\scripts\cleanup-remote-state.ps1 -BucketName "terraform-state-dev" -Force

# Linux/macOS
bash scripts/cleanup-remote-state.sh terraform-state-dev terraform-locks us-east-1 true
```

- [ ] **Confirmed force is necessary** - Discussed with team
- [ ] **Script running** - Watch for progress messages
- [ ] **No errors** - Script completes without errors
- [ ] **Backup created** - Verify backup in `state-backups/` directory

### During Execution
- [ ] **Monitor script output** - Don't leave terminal unattended
- [ ] **Note any warnings** - Document/report them
- [ ] **Watch timestamps** - Note execution took approximately X minutes
- [ ] **No interruptions** - Don't stop script or break connection

---

## Section 7: Post-Execution Verification

### Immediate Verification (Completed within 5 minutes of cleanup finish)
```bash
# Check S3 bucket deleted
aws s3 ls s3://terraform-state-dev --region us-east-1
# Expected: NoSuchBucket error ✓

# Check DynamoDB table deleted
aws dynamodb describe-table --table-name terraform-locks --region us-east-1
# Expected: ResourceNotFoundException error ✓

# Check backup created
ls -la state-backups/  # Linux/macOS
dir state-backups/    # Windows PowerShell
# Expected: state-backup-TIMESTAMP.zip file exists ✓
```

- [ ] **S3 bucket deleted** - NoSuchBucket error when listing
- [ ] **DynamoDB table deleted** - ResourceNotFoundException when describing
- [ ] **AWS Console verified** - Manually checked in S3 and DynamoDB in AWS console
- [ ] **Backup file exists** - Visible in `state-backups/` directory
- [ ] **Backup is readable** - Can list contents if needed:
  ```bash
  unzip -t state-backups/state-backup-*.zip
  ```

### Documentation (Complete within 15 minutes of cleanup finish)

- [ ] **Cleanup reported** - Document in team wiki/confluence
- [ ] **Date and time recorded** - When cleanup occurred
- [ ] **Duration noted** - How long it took
- [ ] **Team members listed** - Who executed the cleanup
- [ ] **Any issues documented** - Problems encountered and resolved
- [ ] **Backup location noted** - Where state backup is stored
- [ ] **Result announced** - Team notified of successful cleanup

### Local Cleanup (Optional but recommended)

```bash
# Remove Terraform cache
cd environments/dev
rm -rf .terraform
rm -f .terraform.lock.hcl

# If also removing state
rm -f terraform.tfstate*
```

- [ ] **Local .terraform removed** - Space freed
- [ ] **Lock file removed** - `.terraform.lock.hcl` deleted
- [ ] **Git status clean** - No uncommitted changes except for cleanup

---

## Section 8: Post-Cleanup Actions

Choose actions based on what you'll do next:

### If Decommissioning Completely
- [ ] **Git archive created** - Full repo backed up with external storage
- [ ] **Documentation preserved** - CLEANUP_GUIDE.md saved for future reference
- [ ] **Backup moved to secure storage** - Off-site backup of `state-backups/`
- [ ] **Team aware** - No more Terraform deployments expected

### If Migrating to New Backend
- [ ] **New backend infrastructure created** - S3 + DynamoDB setup
- [ ] **New backend configuration prepared** - `backend.tfbackend` files ready
- [ ] **Team trained on new backend** - Documentation shared
- [ ] **First `terraform init` with new backend tested** - Successful

### If Using Local State Only
- [ ] **`.gitignore` updated** - Excludes local state files
- [ ] **Team aware of local state** - Updated documentation
- [ ] **Local state backups planned** - Regular git commits sufficient
- [ ] **No concurrent runs** - Only one person using this state at a time

---

## Section 9: Incident Response (If something goes wrong)

### Partial Cleanup (Only S3 deleted, DynamoDB not)
```bash
# Delete DynamoDB table manually
aws dynamodb delete-table --table-name terraform-locks --region us-east-1
```

- [ ] **Remaining resource identified** - Know what's still there
- [ ] **Manually deleted** - Using AWS CLI or console
- [ ] **Verified deleted** - Confirmed in AWS
- [ ] **Incident logged** - Documented what happened

### Accidental Cleanup (State deleted but still needed)
- [ ] **STOP immediately** - Don't do anything else
- [ ] **Restore from backup** - Extract `state-backups/state-backup-*.zip`
- [ ] **Recreate backend** - Run `bash scripts/setup-remote-state.sh`
- [ ] **Import state** - Use `terraform import` if needed

### Cleanup Failed (Errors during script execution)
- [ ] **Error logged** - Save full terminal output
- [ ] **Check AWS for partial deletion** - S3 and DynamoDB status
- [ ] **Manual cleanup** - Use AWS CLI commands if needed
- [ ] **Incident report** - Document what failed and why

**Incident Report Template:**
```
Date: _______________
Time: _______________
Incident: ___________________________________________________
Error Message: ________________________________________________
Status: ○ Resolved ○ Escalated ○ Rolled Back
Resolution: ___________________________________________________
```

---

## Section 10: Final Sign-Off

### Cleanup Executor Sign-Off

| Item | Status |
|------|--------|
| Cleanup script executed successfully | ☐ Yes ☐ No |
| S3 bucket verified deleted | ☐ Yes ☐ No |
| DynamoDB table verified deleted | ☐ Yes ☐ No |
| Backup file created | ☐ Yes ☐ No |
| Team notified | ☐ Yes ☐ No |
| Documentation updated | ☐ Yes ☐ No |

**Executor Name:** _________________________________

**Executor Signature:** _______________________________

**Date:** _____________  **Time:** _____________

---

### Team Lead Approval

By signing below, I confirm that:
- ✓ The cleanup was authorized
- ✓ All prerequisites were completed
- ✓ The backup is secure
- ✓ The team is aware of the cleanup

**Lead Name:** _________________________________

**Lead Signature:** _______________________________

**Date:** _____________  **Time:** _____________

---

## Section 11: Lessons Learned (Post-Cleanup Review)

Conduct this review 1-3 days after cleanup:

**What went well?**
- [ ] Planning was clear
- [ ] Team coordination smooth
- [ ] Execution without issues
- [ ] Communication effective

**What could be improved?**
- [ ] Pre-check procedure
- [ ] Documentation clarity
- [ ] Script functionality
- [ ] Team communication

**Action items for next time:**
- Improvement 1: ________________________________________________
- Improvement 2: ________________________________________________
- Improvement 3: ________________________________________________

**Reviewed by:** ________________  **Date:** _____________

---

## Appendix: Emergency Contacts

In case of critical issues:

| Role | Name | Phone | Email |
|------|------|-------|-------|
| Team Lead | _____________ | _____________ | _____________ |
| AWS Admin | _____________ | _____________ | _____________ |
| DevOps Lead | _____________ | _____________ | _____________ |
| Escalation | _____________ | _____________ | _____________ |

---

## IMPORTANT REMINDERS

✅ **DO:**
- Read CLEANUP_GUIDE.md completely
- Verify all backups exist
- Destroy infrastructure first (terraform destroy)
- Test commands locally first
- Have team sign-off
- Verify deletion afterwards

❌ **DON'T:**
- Rush through cleanup
- Skip backup verification
- Cleanup during business hours
- Run cleanup without team awareness
- Ignore error messages
- Proceed if you're unsure

---

**Last Updated:** [Date]
**Next Review Date:** [Date + 6 months]

