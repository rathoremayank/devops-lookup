# Git Source Control: Enterprise Scenarios & Interview Questions
## Senior DevOps Engineering Study Guide - Part 4 (Final)

---

## Table of Contents

1. [Hands-on Scenarios](#hands-on-scenarios)
   - Scenario 1: Emergency Incident - Accidental Credential Leak
   - Scenario 2: Repository Performance Crisis at Scale
   - Scenario 3: Multi-Team Merge Conflict Resolution
   - Scenario 4: Distributed Team Synchronization Failure
   - Scenario 5: Production Rollback and History Recovery

2. [Interview Questions for Senior DevOps Engineers](#interview-questions)

---

# Hands-on Scenarios

## Scenario 1: Emergency Incident - Accidental Credential Leak

### Problem Statement

At 03:47 UTC, monitoring alerts triggered: AWS credential (`AKIA...`) detected in public GitHub repository. The infrastructure team pushed a Terraform configuration file containing hardcoded AWS access keys (admin-level). The repository is public, 500+ external developers have cloned it, and the credentials were exposed for ~2 hours before detection.

**Immediate Impact:**
- Credentials visible in repository history
- Already cloned by unknown parties
- AWS console shows suspicious activity (failed s3 access from unfamiliar IPs)
- 15+ team members have local copies

### Architecture Context

```
Git Repository Structure:
  infrastructure/
  ├── terraform/
  │   ├── prod/
  │   │   ├── main.tf
  │   │   ├── secrets.tf ← Exposed credentials here
  │   │   └── variables.tf
  │   └── staging/
  └── ansible/

Credential Exposure:
  - Commit: abc123def456 (2 hours old)
  - Author: developer (devops@company.com)
  - Contents: AWS_ACCESS_KEY_ID=AKIA...
           AWS_SECRET_ACCESS_KEY=...

Cloned by: Unknown count (public repo)
```

### Step-by-Step Troubleshooting & Resolution

**Phase 1: Immediate Response (First 5 minutes)**

```bash
#!/bin/bash
# incident-response.sh - Immediate actions

echo "=== SECURITY INCIDENT RESPONSE ==="
date
echo ""

# STEP 1: Revoke credentials immediately (AWS IAM)
echo "Step 1: Revoking AWS credentials..."
aws iam delete-access-key --access-key-id AKIA...
echo "✅ AWS credentials revoked"

# STEP 2: Create new credentials
echo ""
echo "Step 2: Generating replacement credentials..."
NEW_CREDENTIALS=$(aws iam create-access-key \
  --user-name terraform-deployer \
  --output json)
echo "✅ New credentials created"
echo "$NEW_CREDENTIALS" | jq '.AccessKey'

# STEP 3: Verify compromise (check AWS CloudTrail)
echo ""
echo "Step 3: Checking AWS CloudTrail for unauthorized access..."
aws cloudtrail lookup-events \
  --lookup-attributes AttributeKey=Username,AttributeValue=terraform-deployer \
  --max-items 100 \
  --query 'Events[?EventTime>`2026-03-18T01:47:00`].{Time:EventTime,Event:EventName}' \
  --output table

# STEP 4: Rotate all secrets
echo ""
echo "Step 4: Rotating all secrets..."
# Vault, AWS Secrets Manager, etc.
vault write database/rotate-root/infrastructure-prod

# STEP 5: Notify team
echo ""
echo "Step 5: Notifying team..."
cat << 'EMAIL' | mail -s "SECURITY: Credential Exposure in Git" devops@company.com
URGENT: Security incident detected

Credentials exposed in public repository at 01:47 UTC.
Actions taken:
- AWS IAM access keys revoked
- New credentials generated
- CloudTrail audited for unauthorized access
- All team members rotated credentials

See: https://jira.company.com/SEC-1234
Incident channel: #incident-response
EMAIL

echo "✅ Response initiated"
```

**Phase 2: Remediation (Within 30 minutes)**

```bash
#!/bin/bash
# remediation.sh - Fix repository history

set -e

echo "=== Repository Remediation ==="
echo ""

# STEP 1: Clone repository to isolated machine
echo "Step 1: Clone repository to isolated environment..."
WORK_DIR="/tmp/git-remediation-$$"
git clone https://github.com/company/infrastructure.git "$WORK_DIR"
cd "$WORK_DIR"

# STEP 2: Use BFG Repo-Cleaner to remove credentials
echo ""
echo "Step 2: Removing credentials from history..."
echo "AKIA.*" > /tmp/secrets-to-remove.txt
echo "aws_secret_access_key" >> /tmp/secrets-to-remove.txt

bfg --replace-text /tmp/secrets-to-remove.txt

# Alternative: git filter-branch method
# git filter-branch --tree-filter 'grep -l "aws_secret" . && \
#   sed -i "s/AKIA[A-Z0-9]*/REDACTED/g" *' HEAD~5..HEAD

# STEP 3: Reclaim space
echo "✅ Credentials removed from history"
echo ""
echo "Step 3: Reclaiming disk space..."
git reflog expire --expire=now --all
git gc --prune=now --aggressive
echo "✅ Repository cleaned"

# STEP 4: Verify removal
echo ""
echo "Step 4: Verifying credentials removed..."
if git log -p --all | grep -q "AKIA"; then
    echo "❌ Credentials still present!"
    exit 1
else
    echo "✅ Credentials verified removed"
fi

# STEP 5: Force push cleaned repository
echo ""
echo "Step 5: Pushing cleaned repository to GitHub..."
echo "WARNING: Force push will rewrite history for all developers"
read -p "Proceed with force push? (type 'YES')" confirm

if [ "$confirm" != "YES" ]; then
    echo "❌ Remediation cancelled"
    exit 1
fi

git push origin --force --all
git push origin --force --tags
echo "✅ Repository pushed (history rewritten)"

# STEP 6: Notify developers
echo ""
echo "Step 6: Notifying developers about history rewrite..."
cat << 'NOTICE' | mail -s "Git History Rewritten - Action Required" devops@company.com
Repository history has been rewritten to remove exposed credentials.

Required actions for all developers:
  cd infrastructure
  git fetch origin
  git reset --hard origin/main
  
  # If you have local branches:
  git branch -D feature-branch  # Delete old branches
  git fetch origin
  git checkout -b feature-branch origin/feature-branch

Local branches with >=5 commits should be rebased:
  git rebase origin/main

Questions: Slack #devops
NOTICE

echo ""
echo "=== Remediation Complete ==="
echo "All credentials removed from repository history"
echo "Developers notified of required actions"

# Cleanup
cd /
rm -rf "$WORK_DIR"
rm -f /tmp/secrets-to-remove.txt
```

**Phase 3: Verification & Hardening (Ongoing)**

```bash
#!/bin/bash
# hardening.sh - Prevent future incidents

set -e

echo "=== Git Repository Hardening ==="
echo ""

# STEP 1: Pre-commit hook to detect secrets
echo "Step 1: Installing secret detection hook..."

cat > .git/hooks/pre-commit << 'HOOK'
#!/bin/bash
# Prevent committing credentials

PATTERNS=(
    "AKIA[0-9A-Z]{16}"                           # AWS access key
    "aws_secret_access_key"                      # AWS secret
    "password\s*=\s*['\"].*['\"]"               # Passwords
    "private_key_id"                             # Service account keys
    "client_secret"                              # OAuth secrets
    "api_key.*="                                 # API keys
)

ERROR=0
for pattern in "${PATTERNS[@]}"; do
    if git diff --cached | grep -E "$pattern" > /dev/null; then
        echo "❌ Potential secret detected: $pattern"
        ERROR=1
    fi
done

if [ $ERROR -eq 1 ]; then
    echo ""
    echo "Use: --no-verify to bypass (NOT RECOMMENDED)"
    exit 1
fi

exit 0
HOOK
chmod +x .git/hooks/pre-commit
echo "✅ Secret detection hook installed"

# STEP 2: Update .gitignore
echo ""
echo "Step 2: Updating .gitignore..."
cat >> .gitignore << 'IGNORE'

# Credentials and secrets
.env
*.key
*.pem
credentials.json
aws/credentials
secrets/
.vault
IGNORE
echo "✅ .gitignore updated"

# STEP 3: Pre-push validation
echo ""
echo "Step 3: Installing pre-push hook..."
cat > .git/hooks/pre-push << 'HOOK'
#!/bin/bash
# Validate before pushing

echo "Validating changes before push..."

# Check for large files (often credentials)
while IFS= read -r ref; do
    if [ -f "$ref" ]; then
        SIZE=$(stat -f%z "$ref" 2>/dev/null || stat -c%s "$ref" 2>/dev/null)
        if [ "$SIZE" -gt 1000000 ]; then  # 1MB
            echo "❌ Large file detected: $(basename $ref) ($SIZE bytes)"
            exit 1
        fi
    fi
done

# Check recent changes
git diff --cached --name-only | grep -E '\.(key|pem|json|cred)$' && \
    echo "❌ Sensitive file types detected" && exit 1

exit 0
HOOK
chmod +x .git/hooks/pre-push
echo "✅ Pre-push validation installed"

# STEP 4: Enable branch protection
echo ""
echo "Step 4: Configuring branch protection..."
gh api repos/company/infrastructure/branches/main/protection \
  --input - << 'PROTECTION'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["secret-detection"]
  },
  "enforce_admins": true,
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": true,
    "required_approving_review_count": 2
  },
  "require_commit_signoff": true
}
PROTECTION
echo "✅ Branch protection configured"

# STEP 5: Secret scanning service
echo ""
echo "Step 5: Enabling GitHub secret scanning..."
gh api repos/company/infrastructure \
  -X PATCH \
  -f secret_scanning=true \
  -f secret_scanning_push_protection=true
echo "✅ Secret scanning enabled"

# STEP 6: Audit and education
echo ""
echo "Step 6: Post-incident audit..."
echo ""
echo "Create post-incident review:"
echo "- How credentials leaked (root cause)"
echo "- Why not detected earlier"
echo "- Training for team"
echo "- Process improvements"
echo ""
echo "Recommended changes:"
echo "1. Use AWS IAM roles instead of access keys"
echo "2. Use Terraform variables + HashiCorp Vault for secrets"
echo "3. Implement pre-commit hooks organization-wide"
echo "4. Regular security audits of Git history"

echo ""
echo "=== Hardening Complete ==="
```

### Best Practices Applied

**Immediate Response:**
- ✅ Revoke credentials in minutes (not hours)
- ✅ Identify scope of compromise (CloudTrail)
- ✅ Create new credentials immediately
- ✅ Document incident timeline

**Remediation:**
- ✅ Remove from history (not just delete file)
- ✅ Use BFG for safer history rewriting
- ✅ Force push with team notification
- ✅ Verify removal before considering resolved

**Prevention:**
- ✅ Pre-commit hooks detect patterns
- ✅ .gitignore prevents common mistakes
- ✅ Branch protection enforces review
- ✅ Secret scanning catches mistakes
- ✅ Shift from access keys to IAM roles

---

## Scenario 2: Repository Performance Crisis at Scale

### Problem Statement

Infrastructure team reports Git operations slow:
- Clone time: 120+ seconds (should be <30s)
- Fetch time: 60+ seconds after shallow operations
- Developer productivity: "Git is unusable"
- CI/CD pipelines timing out

Investigation reveals: Repository reached 8GB, 500K+ loose objects, packfiles fragmented across 20+ files. Recent infrastructure-as-code changes added 50MB of binary Terraform state files.

### Architecture Context

```
Repository Growth Timeline:
  6 months ago: 500MB (reasonable)
  3 months ago: 1.2GB (added binary artifacts)
  1 month ago: 3GB (state files accumulating)
  1 week ago: 5GB (large policy documents)
  Today: 8GB (crisis point)

Performance Metrics (Current):
  Clone: 120s (target: 30s)
  Fetch fresh: 60s (target: 5s)
  Push: 45s average (target: 10s)
  Log query: 15s (target: 1s)
  Blame: 30s+ (unusable)

Root Causes:
  1. 200MB Terraform state files in history
  2. 150MB binary policy documents
  3. 500K loose objects (should be <5K)
  4. Fragmented packfiles (20 files, not consolidated)
  5. No garbage collection in 6 months
```

### Step-by-Step Troubleshooting & Resolution

**Phase 1: Analysis**

```bash
#!/bin/bash
# analyze-repo.sh - Diagnose repository bloat

echo "=== Repository Performance Analysis ==="
echo ""

echo "1. Repository Size:"
du -sh .git
echo ""

echo "2. Object Count:"
git count-objects -v
echo ""

echo "3. Largest Objects (top 10):"
git rev-list --all --objects | \
  sed 's/ .*//' | \
  git cat-file --batch-check | \
  grep blob | \
  sort -k3 -nr | \
  head -10 | \
  while read hash type size; do
    echo "  $size bytes: $(git rev-parse --short $hash)"
  done
echo ""

echo "4. Objects by Commit:"
git log --pretty=format:%H | head -20 | while read commit; do
  SIZE=$(git cat-file -s $commit 2>/dev/null || echo 0)
  echo "  $(git rev-parse --short $commit): $SIZE bytes"
done
echo ""

echo "5. Packfile Status:"
if [ -d .git/objects/pack ]; then
  echo "  Number of packfiles: $(ls .git/objects/pack/*.pack 2>/dev/null | wc -l)"
  echo "  Total packfile size: $(du -sh .git/objects/pack | cut -f1)"
  echo ""
  echo "  Individual packfiles:"
  ls -lh .git/objects/pack/*.pack 2>/dev/null | \
    awk '{print "    " $9 ": " $5}'
else
  echo "  No packfiles found"
fi
echo ""

echo "6. Loose Objects:"
LOOSE=$(find .git/objects -type f ! -path '*/pack/*' | wc -l)
echo "  Count: $LOOSE (target: <5000)"
echo "  Recommendation: Run gc if > 10000"
echo ""

echo "7. Repository Age:"
FIRST_COMMIT=$(git log --reverse --oneline | head -1 | awk '{print $1}')
FIRST_DATE=$(git show -s --format=%ci $FIRST_COMMIT)
echo "  First commit: $FIRST_DATE"
echo ""

echo "8. Reflog Size:"
git reflog expire --dry-run 2>/dev/null | wc -l
echo "  References with history: $(git rev-list --all | wc -l)"
```

**Phase 2: Remediation**

```bash
#!/bin/bash
# aggressive-cleanup.sh - Perform full repository cleanup

set -e

echo "=== Aggressive Repository Cleanup ==="
echo ""

BACKUP_DIR="/backups/infrastructure-repo-$(date +%s)"

# STEP 1: Create backup
echo "Step 1: Creating backup..."
mkdir -p "$BACKUP_DIR"
git bundle create "$BACKUP_DIR/backup-$(date +%Y%m%d).bundle" --all
echo "✅ Backup created: $BACKUP_DIR"
echo ""

# STEP 2: Identify bloat
echo "Step 2: Identifying objects to remove..."
BLOAT_THRESHOLD=50000000  # 50MB

echo "Objects larger than $(($BLOAT_THRESHOLD/1000000))MB:"
git rev-list --all --objects | \
  sed 's/ .*//' | \
  git cat-file --batch-check | \
  awk -v threshold=$BLOAT_THRESHOLD \
  '$3 > threshold {print $3, $1}' | \
  sort -rn | \
  while read size hash; do
    echo "  $((size/1000000))MB: $hash"
    # Find in which commits
    git log --all --pretty=format:'    %H %s' -- $(git rev-list -1 $hash^{tree} 2>/dev/null)
  done
echo ""

# STEP 3: Remove state files (if present)
echo "Step 3: Removing Terraform state files..."
bfg --delete-files '*.tfstate'
bfg --delete-files '*.tfstate.backup'
bfg --delete-files 'terraform.tfstate*'
echo "✅ State files removed"
echo ""

# STEP 4: Remove large binary files
echo "Step 4: Removing large binaries..."
bfg --delete-files '*.iso'
bfg --delete-files '*.vmdk'
bfg --delete-files '*.tar.gz' | head -20  # Sample
echo "✅ Large binaries removed"
echo ""

# STEP 5: Update gitignore for future
echo "Step 5: Updating .gitignore..."
cat >> .gitignore << 'IGNORE'

# Terraform state files (use remote state!)
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl

# Large binaries
*.iso
*.vmdk
*.raw

# Build artifacts
dist/
build/

# OS files
.DS_Store
Thumbs.db

# Virtual environments
venv/
node_modules/
IGNORE
git add .gitignore
git commit -m "chore: improve gitignore to prevent repo bloat"
echo "✅ .gitignore updated"
echo ""

# STEP 6: Consolidate and optimize
echo "Step 6: Consolidating packfiles..."
git reflog expire --expire=now --all
git gc --prune=now --aggressive
echo "✅ Garbage collection complete"
echo ""

# STEP 7: Verify results
echo "Step 7: Verifying cleanup..."
echo "Before cleanup: 8GB (approximate)"
echo "After cleanup: $(du -sh .git | awk '{print $1}')"
echo ""
git count-objects -v | grep -E '^(count|size|prune)'
echo ""

# STEP 8: Push changes
echo "Step 8: Force pushing cleaned repository..."
echo "⚠️ This will require force push to all branches"
echo "Developers must reset local copies"
echo ""

git push origin --force --all
git push origin --force --tags
echo "✅ Cleaned repository pushed"
echo ""

echo "=== Cleanup Complete ==="
```

**Phase 3: Performance Optimization**

```bash
#!/bin/bash
# performance-tuning.sh - Ongoing optimization

echo "=== Repository Performance Tuning ==="
echo ""

# STEP 1: Configure Git for performance
echo "Step 1: Configuring Git for performance..."

git config core.compression 9                # Compression level
git config core.packedRefsTimeout 10         # Packed refs update
git config gc.aggressiveWindow 250           # Window size
git config --global transfer.fsckObjects true # Safer transfers

echo "git config values:"
git config --list | grep -E '^(core|gc|transfer)\.'
echo ""

# STEP 2: Use shallow clones in CI/CD
echo "Step 2: Testing shallow clone performance..."

echo "Full clone: " $(time git clone . /tmp/full-clone 2>&1 | grep real)
echo "Shallow clone: " $(time git clone --depth 1 . /tmp/shallow-clone 2>&1 | grep real)
echo "Single branch: " $(time git clone --depth 1 --single-branch . /tmp/single-branch 2>&1 | grep real)

rm -rf /tmp/full-clone /tmp/shallow-clone /tmp/single-branch
echo ""

# STEP 3: Set up sparse checkout for large repos
echo "Step 3: Configuring sparse checkout..."

git config core.sparseCheckout true
mkdir -p .git/info

# Only checkout needed directories
cat > .git/info/sparse-checkout << 'EOF'
/*
!/docs/
!/backups/
EOF

git checkout
echo "✅ Sparse checkout configured"
echo ""

# STEP 4: Large file handling strategy
echo "Step 4: Setting up Git LFS for large files..."

cat > .gitattributes << 'ATTR'
*.tfstate filter=lfs diff=lfs merge=lfs -text
*.iso filter=lfs diff=lfs merge=lfs -text
*.vmdk filter=lfs diff=lfs merge=lfs -text
ATTR

echo "Update root user to push LFS files:"
echo "  git lfs track '*.tfstate'"
echo "  git add .gitattributes"
echo ""

# STEP 5: Automated maintenance
echo "Step 5: Scheduling maintenance..."

cat > /usr/local/bin/git-maintenance-weekly.sh << 'SCRIPT'
#!/bin/bash
# Run weekly repository maintenance

REPOS=(
  /var/git/infrastructure.git
  /var/git/platform.git
)

for repo in "${REPOS[@]}"; do
  if [ -d "$repo" ]; then
    echo "Maintaining $repo..."
    cd "$repo"
    
    # Loose object cleanup
    if [ $(find .git/objects -type f ! -path '*/pack/*' | wc -l) -gt 5000 ]; then
      echo "  Running gc..."
      git gc --aggressive
    fi
    
    # Reflog cleanup (keep 90 days)
    git reflog expire --expire=90.days --all
    
    # Prune unreachable
    git gc --prune=now
  fi
done
SCRIPT

chmod +x /usr/local/bin/git-maintenance-weekly.sh
echo "✅ Maintenance script installed"
echo "  Add to crontab: 0 2 * * 0 /usr/local/bin/git-maintenance-weekly.sh"
echo ""

echo "=== Performance Tuning Complete ==="
```

### Best Practices Applied

**Analysis:**
- ✅ Quantify problem (size, object count, specific slowdowns)
- ✅ Identify root causes (state files, binaries)
- ✅ Create backup before any destructive operations

**Remediation:**
- ✅ Use BFG for safer history rewriting
- ✅ Remove from all commits (not just current)
- ✅ Update .gitignore to prevent recurrence
- ✅ Force push with team coordination

**Optimization:**
- ✅ Configure Git for performance (compression, windows)
- ✅ Use shallow clones in CI/CD
- ✅ Implement sparse checkout for large repos
- ✅ Use Git LFS for large files (not state!)
- ✅ Schedule regular maintenance (weekly gc)

---

## Scenario 3: Multi-Team Merge Conflict Resolution

### Problem Statement

Two autonomous teams (Infrastructure & Platform) need to merge feature branches into `develop`:
- **Team A (Infrastructure):** Terraform refactoring - moved 200+ files, reorganized modules
- **Team B (Platform):** Added new Kubernetes resources, updated ingress configuration
- **Conflict:** Both teams modified shared `terraform/variables.tf`, `kubernetes/kustomization.yaml`, and CI pipeline configuration
- **Complexity:** Teams in different timezones (India & San Francisco)
- **Time pressure:** Release deadline in 6 hours

### Architecture Context

```
Repository State Before Merge:

main
  ↓
develop → A → B → C (Infrastructure team - 5 days old)
      ↓              (refactored modules)
      → D → E → F    (Platform team - 3 days old)
      (new features)

Conflicts Identified:
  terraform/variables.tf       (both modified)
  kubernetes/kustomization.yaml (both modified)
  .github/workflows/deploy.yml  (both modified)
  ansible/site.yml            (only Platform, safe to merge)

File Changes:
  Infrastructure:
    - Moved 200+ terraform files
    - Renamed modules
    - Updated all references (expected: massive diff)
  
  Platform:
    - Added 50 new kubernetes resources
    - Updated deployment strategy
    - Changed ingress endpoints
```

### Step-by-Step Troubleshooting & Resolution

**Phase 1: Pre-Merge Analysis & Planning**

```bash
#!/bin/bash
# pre-merge-analysis.sh

set -e

echo "=== Pre-Merge Analysis ==="
echo ""

# Get branches
BRANCH_A="feature/infrastructure-refactor"
BRANCH_B="feature/platform-features"
TARGET="develop"

git fetch origin

echo "Branch Information:"
echo "  Infrastructure: $(git log --oneline -1 origin/$BRANCH_A | cut -c1-100)"
echo "  Platform: $(git log --oneline -1 origin/$BRANCH_B | cut -c1-100)"
echo ""

# Find common base
COMMON=$(git merge-base origin/$BRANCH_A origin/$BRANCH_B)
echo "Common ancestor: $(git rev-parse --short $COMMON)"
echo ""

# Analyze changes
echo "Changes in Infrastructure branch:"
git diff $COMMON origin/$BRANCH_A --stat | head -20
echo ""

echo "Changes in Platform branch:"
git diff $COMMON origin/$BRANCH_B --stat | head -20
echo ""

# Identify conflicts
echo "=== Conflict Analysis ==="
echo ""

# Test merge (non-destructive)
TEMP_BRANCH="test-merge-analysis-$$"
git checkout -b "$TEMP_BRANCH" origin/$TARGET

echo "Simulating merge of Infrastructure branch..."
if git merge --no-commit --no-ff origin/$BRANCH_A 2>&1 | grep -q "CONFLICT"; then
    echo "  ⚠️ Conflicts detected:"
    git diff --name-only --diff-filter=U | nl
    
    # Show conflict details
    echo ""
    echo "Conflict details:"
    for file in $(git diff --name-only --diff-filter=U); do
        echo ""
        echo "File: $file"
        CONFLICTS=$(grep -c "<<<<<<< HEAD" "$file" || true)
        LINES=$(wc -l < "$file")
        echo "  Conflict sections: $CONFLICTS"
        echo "  Total lines: $LINES"
        
        if [[ "$file" == *.tf ]]; then
            echo "  Type: Terraform - Requires semantic understanding"
        elif [[ "$file" == *.yaml ]]; then
            echo "  Type: Kubernetes - Validate schema after merge"
        else
            echo "  Type: Generic"
        fi
    done
else
    echo "  ✅ No conflicts on Infrastructure merge"
fi

git merge --abort
rm -f "$file"

echo ""
echo "Simulating merge of Platform branch..."
git checkout -b "test-merge-platform-$$" origin/$TARGET

if git merge --no-commit --no-ff origin/$BRANCH_B 2>&1 | grep -q "CONFLICT"; then
    echo "  ⚠️ Conflicts detected:"
    git diff --name-only --diff-filter=U | nl
else
    echo "  ✅ No conflicts on Platform merge"
fi

git merge --abort

# Cleanup
git checkout $TARGET
git branch -D "$TEMP_BRANCH" "test-merge-platform-$$"

echo ""
echo "=== Analysis Complete ==="
echo "Recommendation: Manual merge with team review required"
```

**Phase 2: Synchronous Resolution Meeting**

```bash
#!/bin/bash
# merge-sync-meeting.sh
# Coordinate between teams in real-time

echo "=== Merge Coordination Meeting Script ==="
echo ""
echo "Participants:"
echo "  - Infrastructure Team Lead"
echo "  - Platform Team Lead"
echo "  - DevOps Engineer"
echo ""

echo "Meeting Objective:"
echo "  Resolve merge conflicts and ensure mutual compatibility"
echo ""

echo "Preparation (before meeting):"
echo "1. Each team reviews other's changes"
echo "2. Identify semantic conflicts (not just textual)"
echo "3. Test each change in isolation"
echo ""

# Send info to teams
INFRA_TEAM="infra-team@company.com"
PLATFORM_TEAM="platform-team@company.com"

cat << 'EMAIL' | mail -s "Merge Coordination Meeting - 30 min" $INFRA_TEAM $PLATFORM_TEAM
Pre-Meeting Prep:

Infrastructure Team:
  Review: Platform's Kubernetes changes
  Prepare: 
    - Risk assessment of refactoring with new resources
    - Testing plan for merged code
    - Rollback plan if issues found

Platform Team:
  Review: Infrastructure's terraform refactoring
  Prepare:
    - Compatibility check with new module structure
    - Updated paths in your Kubernetes configs
    - Testing plan

Conflicts to Resolve:
  1. terraform/variables.tf (both modified)
  2. kubernetes/kustomization.yaml (both modified)
  3. .github/workflows/deploy.yml (both modified)

Meeting Agenda (30 minutes):
  1. (5 min) Overview of changes
  2. (10 min) variables.tf conflict resolution
  3. (10 min) kubernetes conflict resolution
  4. (3 min) CI/D pipeline agreement
  5. (2 min) Testing & rollback plan

Location: Slack #merge-coordination
TIME: 2026-03-18T20:00:00 UTC (11:00 PT, 23:00 IST)
EMAIL

echo ""
echo "Post-Meeting: Execute agreed resolution"
```

**Phase 3: Resolution Execution**

```bash
#!/bin/bash
# execute-merge.sh
# Perform merge with resolved conflicts

set -e

BRANCH_A="feature/infrastructure-refactor"
BRANCH_B="feature/platform-features"
TARGET="develop"

echo "=== Executing Merge Resolution ==="
echo ""
echo "Agreed decisions from meeting:"
echo "  1. variables.tf: Keep Infrastructure's structure, add Platform's new vars"
echo "  2. kustomization.yaml: Merge resources from both branches"
echo "  3. deploy.yml: Combine both teams' workflow steps"
echo ""

# STEP 1: Create merge branch
echo "Step 1: Creating merge branch..."
git checkout -b "merge/infra-platform-$(date +%s)" origin/$TARGET
echo "✅ On merge branch"
echo ""

# STEP 2: First merge (Infrastructure)
echo "Step 2: Merging Infrastructure branch..."
git merge --no-edit origin/$BRANCH_A
echo "✅ Infrastructure merged"
echo ""

# STEP 3: Second merge (Platform) - will have conflicts
echo "Step 3: Merging Platform branch (resolving conflicts)..."

if ! git merge --no-commit origin/$BRANCH_B; then
    echo "⚠️ Conflicts detected - resolving"
    
    # CONFLICT 1: terraform/variables.tf
    echo ""
    echo "Resolving: terraform/variables.tf"
    
    # Get versions
    git show :1:terraform/variables.tf > /tmp/variables.ancestor.tf
    git show :2:terraform/variables.tf > /tmp/variables.ours.tf
    git show :3:terraform/variables.tf > /tmp/variables.theirs.tf
    
    # Merge logic: Keep both variable sets
    cat /tmp/variables.ancestor.tf > terraform/variables.tf
    
    # Add Platform's new variables (if not in ancestor)
    grep "variable " /tmp/variables.theirs.tf | while read -r var; do
      if ! grep -q "$var" /tmp/variables.ancestor.tf; then
        echo "$var" >> terraform/variables.tf
      fi
    done
    
    git add terraform/variables.tf
    echo "✅ variables.tf resolved"
    
    # CONFLICT 2: kubernetes/kustomization.yaml
    echo ""
    echo "Resolving: kubernetes/kustomization.yaml"
    
    # Merge YAML resources
    cat /tmp/kustomize.ancestor.yaml > kubernetes/kustomization.yaml
    
    # Extract unique resources from both
    INFRA_RESOURCES=$(grep "^  - " /tmp/kustomize.ours.yaml 2>/dev/null | sort | uniq)
    PLATFORM_RESOURCES=$(grep "^  - " /tmp/kustomize.theirs.yaml 2>/dev/null | sort | uniq)
    
    # Combine
    echo "resources:" >> kubernetes/kustomization.yaml
    echo "$INFRA_RESOURCES" >> kubernetes/kustomization.yaml
    echo "$PLATFORM_RESOURCES" >> kubernetes/kustomization.yaml | sort | uniq
    
    git add kubernetes/kustomization.yaml
    echo "✅ kustomization.yaml resolved"
    
    # CONFLICT 3: .github/workflows/deploy.yml
    echo ""
    echo "Resolving: .github/workflows/deploy.yml"
    
    # Merge workflow steps (append both)
    # Create combined workflow with both teams' steps
    COMBINED=$(cat << 'WORKFLOW'
name: Deploy
on: [push, pull_request]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      # Infrastructure build steps
      - name: Validate Terraform
        run: terraform validate
      
      - name: Plan Terraform
        run: terraform plan -json
      
      # Platform build steps
      - name: Validate Kubernetes
        run: kubeval kubernetes/
      
      - name: Build & Deploy
        run: |
          terraform apply -auto-approve
          kubectl apply -f kubernetes/
WORKFLOW
    )
    
    echo "$COMBINED" > .github/workflows/deploy.yml
    git add .github/workflows/deploy.yml
    echo "✅ deploy.yml resolved"
    
    echo ""
    echo "All conflicts resolved"
fi

# STEP 4: Validate merged result
echo ""
echo "Step 4: Validating merged infrastructure..."

if [ -d terraform ]; then
    if terraform validate terraform/ > /dev/null 2>&1; then
        echo "✅ Terraform validation passed"
    else
        echo "❌ Terraform validation failed"
        terraform validate terraform/
        exit 1
    fi
fi

if [ -d kubernetes ]; then
    if kubeval kubernetes/*.yaml > /dev/null 2>&1; then
        echo "✅ Kubernetes validation passed"
    else
        echo "❌ Kubernetes validation failed"
        kubeval kubernetes/*.yaml
        exit 1
    fi
fi

# STEP 5: Test merged result
echo ""
echo "Step 5: Running tests..."

# Infrastructure tests
echo "  Testing infrastructure..."
terraform plan -json > /tmp/tf-plan.json

# Check for unexpected changes
if jq '.resource_changes | length' /tmp/tf-plan.json | grep -E '^[0-9]{3,}'; then
    echo "  ⚠️ Warning: Large number of infrastructure changes"
    echo "  Review before applying"
fi

echo "✅ Tests passed"
echo ""

# STEP 6: Commit merge
echo "Step 6: Committing merge..."
git commit -m "merge: combine infrastructure refactoring and platform features

Infrastructure changes:
  - Reorganized terraform modules
  - Refactored variable structure
  - Updated all references

Platform changes:
  - Added new Kubernetes resources
  - Updated ingress configuration
  - New deployment workflow steps

Merged by: DevOps Team
Reviewed by: Infrastructure Team Lead, Platform Team Lead

Fixes: #1234, #1235"

echo "✅ Merge committed"
echo ""

# STEP 7: Push and verify
echo "Step 7: Pushing merged code..."
git push origin HEAD:develop
echo "✅ Pushed to develop"

echo ""
echo "=== Merge Complete ==="
echo "Both teams' features successfully integrated"
echo "Ready for testing in staging environment"
```

### Best Practices Applied

**Pre-Merge Planning:**
- ✅ Analyze conflicts before merging
- ✅ Schedule synchronous meeting (async = delays)
- ✅ Document team agreements explicitly
- ✅ Test each change in isolation first

**Merge Resolution:**
- ✅ Semantic merge (not textual, consider meaning)
- ✅ Combine changes intelligently (add resources, don't overwrite)
- ✅ Validate after merge (terraform, kubernetes, etc.)
- ✅ Explicit commit message documenting resolution

**Post-Merge:**
- ✅ All teams aware of final result
- ✅ Rollback plan documented
- ✅ Testing in staging before production
- ✅ Communication channel remains open

---

## Scenario 4: Distributed Team Synchronization Failure

### Problem Statement

Morning standup: Asia-Pacific team reports "cannot push" to main repository. Investigation reveals:
- GitHub experiencing intermittent connectivity
- Regional CDN for mirror repository offline
- Team expected to push a critical hotfix for production incident
- Additional 8 developers cloning fresh repository (new team members)
- Cannot wait for GitHub to recover (incident ongoing)

### Step-by-Step Resolution

**Phase 1: Failover to Local Mirror (5 minutes)**

```bash
#!/bin/bash
# failover-to-mirror.sh

set -e

echo "=== Failover to Local Mirror ==="
echo ""

# STEP 1: Detect GitHub failure
echo "Step 1: Detecting GitHub availability..."
if ! timeout 5 git ls-remote https://github.com/company/infrastructure.git > /dev/null 2>&1; then
    echo "❌ GitHub unreachable"
else
    echo "✅ GitHub reachable (fallback not needed)"
    exit 0
fi

# STEP 2: Switch to local mirror
echo ""
echo "Step 2: Switching to local mirror repository..."

# Local backup repository (from disaster recovery strategy)
MIRROR="/var/git/infrastructure-mirror.git"

if [ ! -d "$MIRROR" ]; then
    echo "❌ Mirror not available: $MIRROR"
    exit 1
fi

REMOTE_URL=$(git remote get-url origin)
echo "  Current remote: $REMOTE_URL"

# Switch to mirror
git remote set-url origin "$MIRROR"
echo "  New remote: $(git remote get-url origin)"

git fetch origin
echo "✅ Switched to mirror"
echo ""

# STEP 3: Continue work
echo "Step 3: Resuming work on mirror..."
echo "Hotfix PR: feature/critical-fix"

# Create hotfix
git checkout -b feature/critical-fix origin/main
# Make fixes...
git add .
git commit -m "hotfix: critical production issue

Addressed: Database connection pooling bug
Impact: Reduced P99 latency by 40%
Verified: Local testing passed

Fixes: #9999 [CRITICAL]"

git push origin feature/critical-fix
echo "✅ Hotfix pushed to mirror"
echo ""

# STEP 4: Queue for sync to primary
echo "Step 4: Queuing for sync to primary..."

SYNC_LOG="/var/git/pending-syncs.log"
cat >> "$SYNC_LOG" << 'ENTRY'
2026-03-18T11:30:00Z feature/critical-fix
ENTRY

echo "  Sync queued (will auto-sync when GitHub recovers)"
echo ""
```

**Phase 2: Coordinate Team Across Regions**

```bash
#!/bin/bash
# coordinate-team.sh

echo "=== Team Coordination During Outage ==="
echo ""

# Create coordination channel
cat << 'SLACK' | mail -s "GitHub Outage: Using Local Mirror" #devops-apac
🔴 GitHub experiencing connectivity issues

Action taken:
  ✅ Switched to local mirror repository
  ✅ All services continue normally
  ✅ Work NOT lost (mirrored daily)

What to do:
  1. Fetch latest: git fetch origin
  2. Continue pushing/pulling NORMALLY
  3. Commands work exactly as before

Transparency:
  When did this start? 11:27 UTC
  When should GitHub recover? Monitoring...
  What if GitHub stays down? We have 30-day local history

For new team members:
  Same as normal: git clone <mirror-url>
  Access: Ask #devops for mirror URL
SLACK

echo "Team notified of status"
```

---

## Scenario 5: Production Rollback and History Recovery

### Problem Statement

Production incident at 21:45 UTC: Terraform deployment (commit `def789a`) inserted misconfigured security groups, blocking all incoming traffic. Users affected: 100%. Duration: 15 minutes before detection. Immediate action: Revert to last known good state (`abc456d` from 30 minutes prior).

### Step-by-Step Recovery

**Phase 1: Immediate Rollback (< 5 minutes)**

```bash
#!/bin/bash
# immediate-rollback.sh

set -e

echo "=== PRODUCTION ROLLBACK ==="
echo ""

# STEP 1: Verify current state
echo "Step 1: Current production state"
git rev-parse HEAD
echo ""

# STEP 2: Create rollback commit
echo "Step 2: Creating rollback commit"
GOOD_COMMIT="abc456d"

git revert --no-edit $GOOD_COMMIT..HEAD
# Or safer: create new commit reverting to known-good state
git reset --soft $GOOD_COMMIT
git commit -m "revert: rollback to known good state after security group incident

Incident: Misconfigured security groups blocked all traffic
Duration: 15 minutes
Impact: 100% service degradation
Root cause: Terraform variable error

Reverted commits:
  - def789a (bad SG config)"

echo "✅ Rollback commit created"
echo ""

# STEP 3: Deploy rollback
echo "Step 3: Deploying rollback"
git push origin main
# CI/CD auto-triggers on main push
echo "✅ Rollback deployed"
echo ""

# STEP 4: Verify recovery
echo "Step 4: Verifying recovery"
sleep 5
curl -s https://api.company.com/health | jq .
echo "✅ Service responding"
```

**Phase 2: Post-Incident Analysis**

```bash
#!/bin/bash
# post-incident-analysis.sh

echo "=== Post-Incident Analysis ==="
echo ""

BAD_COMMIT="def789a"
GOOD_COMMIT="abc456d"

echo "Timeline:"
echo "  $(git show -s --format='%ci %s' $GOOD_COMMIT) - Last good state"
echo "  $(git show -s --format='%ci %s' $BAD_COMMIT) - Incident deployed"
echo ""

echo "Bad commit details:"
git show --stat $BAD_COMMIT
echo ""

echo "Changes that caused incident:"
git diff $GOOD_COMMIT $BAD_COMMIT | grep -A5 "security_group"
echo ""

echo "Query: What was the developer thinking?"
git log --all --grep="SG\|security" --oneline | head -5
echo ""

echo "Recommendations:"
echo "1. Add security group validation to pre-commit hooks"
echo "2. Require security team approval for SG changes"
echo "3. Staging validation (test SG rules)"
echo "4. Add monitoring for sudden traffic drops"
```

---

# Interview Questions

## Q1: Explain Git's internal object model and why it matters for large-scale deployments

**Expected Answer (Senior Level):**

Git stores everything as immutable objects identified by content hashes (SHA-1 or SHA-256). There are four types:

1. **Blob** - Raw file content. Two identical files anywhere in history share one blob (deduplication)
2. **Tree** - Directory snapshots mapping filenames to blobs/trees at a point in time
3. **Commit** - Points in history containing tree reference, parent(s), author/committer, timestamp, message
4. **Tag** - Named references to commits (annotated tags are objects themselves)

**Why this matters for deployments:**

- **Reproducibility**: Commit hash encodes entire state. Deploying from abc123d always produces identical infrastructure
- **Integrity**: Any corruption changes hash. Automatically detected, not silent failures
- **History compression**: Identical files deduplicate (one file × 100 commits = one blob)
- **Audit trail**: Immutable history means "who changed what and when" is permanent evidence
- **Distributed safety**: Each developer has complete history + verification via hashes

**Real-world example:** 
Infrastructure repo with 500 Terraform files, 1000 commits. Without deduplication: 500MB. With deduplication (Git's approach): 50-100MB. On CI/CD systems with 1000 parallel jobs: saving 400MB × 1000 = 400GB bandwidth per day.

---

## Q2: Why would you choose Git Flow over trunk-based development for infrastructure?

**Expected Answer (Senior Level):**

**Trunk-based = fast iteration, continuous deployment**
- Single branch (main)
- Daily commits to main
- Automated deployment from main
- Best for: DevOps, infrastructure-as-code teams, continuous deployment culture

**Git Flow = coordinated releases, multiple environments**
- main = production only
- develop = integration
- feature branches
- release branches
- Best for: Products with scheduled releases, supporting multiple versions simultaneously

**For infrastructure specifically:**

Most infrastructure teams should use **trunk-based development** because:

1. **Infrastructure is service, not versioned product**
   - Version based on deployment time, not release cycles
   - All changes go to production within hours
   - No "supporting 3 versions at once" requirement

2. **GitOps relies on main being always deployable**
   - ArgoCD, Flux watch main branch
   - Pull from main = pull production state
   - Failure modes: If main is not production-ready, cluster diverges

3. **Disaster recovery is simpler**
   - Main always runnable
   - Revert to any main commit = known state
   - No "was this in develop or main?" confusion

4. **Team scaling is easier**
   - Short branches (hours, not weeks)
   - Fewer merge conflicts
   - Daily integration catches issues early
   - 50+ person teams handle 100+ merge/day

**Exception: Supporting multiple cloud providers**
- AWS main = v2.3
- GCP develop = v3.0 (testing)
- Then release v3.0 branch when ready
- But still: Each branch is trunk-based (not GitFlow on top)

---

## Q3: Describe a production incident caused by Git workflow failure and how you fixed it

**Expected Answer (Senior Level):**

**Incident: Database migration deployed during business hours**

**Root cause:** Feature branch created from old main (2 weeks stale), developer didn't rebase before merge. Main had other changes that made migration no longer compatible. Merge conflict manually resolved incorrectly.

**What went wrong:**
```
main → A → B (db fixes)
    ↗ feature → C (db migration - based on before B)
After merge, mix of B (fixes) + C (migration) created conflict
Developer resolved wrong + deployed
```

**Symphony of failures:**
- Long-lived feature branch (should rebase weekly)
- Manual conflict resolution without review
- Merge conflict not tested pre-deployment
- No staging validation (would've caught)

**Fix implemented:**

1. **Rebase discipline**
   ```
   git config branch.autosetuprebase local
   ```
   Auto-rebase pulls. Check: git fetch regularly, rebase on main weekly.

2. **Merge validation**
   Before merge PR, run: terraform plan, tests
   Show plan as PR comment (review changes!)

3. **Staging gate**
   Never merge directly main→prod
   Path: feature → develop (testing) → main (merge) → prod (deploy)

4. **Pre-merge testing**
   ```bash
   git fetch origin
   git merge --no-commit origin/feature
   # Run full validation (TF plan, tests, etc.)
   git merge --abort
   ```

**Prevention going forward:**
- Feature branches: max 3 day lifetime (or auto-rebase)
- Merge conflicts: cannot merge until CI validates
- Staging deployment: required before main; staged prod deployment shows plan
- Incident review triggered pre-merge alerts

---

## Q4: How would you structure a monorepo for 10 teams without constant merge conflicts?

**Expected Answer (Senior Level):**

**The challenge:** 10 teams, one monorepo, shared files (terraform/variables.tf, kubernetes/kustomization.yaml) = merge conflicts daily.

**Solution: Owned directories + required approvals**

**Repository structure:**
```
infrastructure/
├── terraform/
│   ├── global/                    (shared, CODEOWNERS: platform-team)
│   ├── aws/
│   │   ├── prod/                 (owned: infra-prod-team)
│   │   ├── staging/              (owned: infra-staging-team)
│   │   └── dev/                  (owned: devs)
│   └── modules/                  (owned: infra-team)
├── kubernetes/
│   ├── shared-services/          (owned: platform-team)
│   ├── app-team-a/               (owned: team-a)
│   └── app-team-b/               (owned: team-b)
└── ansible/
```

**CODEOWNERS file:**
```
# Git requires approval from owner
terraform/global/*              @platform-team
terraform/modules/*             @infra-team
terraform/aws/prod/*            @infra-prod-team
kubernetes/shared-services/*    @platform-team
kubernetes/app-team-a/*         @app-team-a
```

**Merge conflict prevention strategy:**

1. **Reduce shared files**
   - Variables: terraform modules over monolithic file
   - Kubernetes: Kustomization per team, composite at deployment
   - CI/CD: Shared template, not shared file editing

2. **Short-lived branches (critical!)**
   - Branch policy: max 2-day lifetime
   - Daily rebase on main (catches issues early)
   - Reduced chance of concurrent edits

3. **Async + Sync approval**
   - CODEOWNERS: async review (can merge after review)
   - Shared files: sync review (meeting required before merge)

4. **Atomic, focused commits**
   - Single change per commit
   - Related to one logical task
   - Reviewed as unit

5. **Test before merge**
   - CI runs on every PR
   - Must pass all tests
   - Merge conflict detection hooks
   - Infrastructure validation (TF plan, K8s schema)

**Real conflict handling:**
```bash
# Team A and B both modify terraform/variables.tf
# Resolution:
#   1. Extract each team's variables to separate files
#   terraform/variables-team-a.tf
#   terraform/variables-team-b.tf
#   terraform/variables.tf (includes both)
#   
#   2. Commit resolving merge + restructure
#   3. Future: Each team modifies only their own file
```

**Scale to 50 teams:**
- Add team-specific subdirectories (enforced by CODEOWNERS)
- Implement monorepo split tools (Bazel, Nx) for dependency tracking
- Daily cross-team syncs for shared infrastructure
- Tools: monorepo linters for dependency violations

---

## Q5: Your team uses feature branches with weekly rebases. A developer accidentally force-pushed an old version of main. How do you recover?

**Expected Answer (Senior Level):**

**Incident:** Developer A rebased locally, force-pushed old main to origin/main. Other developers pulling now get wrong history.

**First response (30 seconds):**
```bash
# Immediately revert force push
git push --force origin refs/heads/main@{1}:refs/heads/main

# Or find original commit in reflog
git reflog
# Get old main ref
git push --force origin <original-main-hash>:refs/heads/main
```

**Team recovery (2-3 minutes):**
```bash
# For each developer:
git fetch origin
git reset --hard origin/main
git clean -fd
```

**Root cause analysis:**
- Why did developer have permissions to force push main?
  - Should be **prevented at server level** (not permission issue)
  - GitHub/GitLab branch protection rules

**Prevention:**
```bash
# GitHub Actions or pre-push hook:
# (1) Server-side: Prevent force push entirely
gh api repos/company/infrastructure/branches/main/protection \
  --input - << 'JSON'
{
  "restrict_who_can_push": {
    "teams": [],
    "users": []                    # NO ONE can force push
  }
}
JSON

# (2) Or: Allow force push only from CI
git config receive.denyNonFastForwards true

# (3) Or: Require force push approval
# Pre-push hook
#!/bin/bash
git push --force-with-lease
# (safer: fails if remote changed)
```

**Lesson:** 
- Individual developers should never need force push to shared branches
- Force push should only come from automated rebasing tools (not human)
- If needed: `--force-with-lease` (safer), not `--force`

---

## Q6: Explain the difference between `git pull` and `git fetch` and when you'd use each

**Expected Answer (Senior Level):**

**git fetch:**
- Downloads commits/refs from remote
- Updates remote-tracking branches (origin/main)
- Does NOT modify local branches
- Does NOT modify working directory
- Safe for exploration

```bash
git fetch origin                    # Get latest
git log main..origin/main           # See what's new
git diff main...origin/main         # See differences
```

**git pull:**
- Convenience: fetch + merge/rebase all-in-one
- Downloads commits AND auto-integrates
- May create merge commit
- May cause conflicts
- Less safe (doesn't let you review first)

```bash
git pull                            # fetch + merge FETCH_HEAD
git pull --rebase                   # fetch + rebase on upstream
```

**Real-world preference:** 
Senior engineers almost always use **fetch first, then consciously choose merge or rebase**.

```bash
# Workflow:
git fetch origin
git log main..origin/main           # "What changed?"
git diff main...origin/main         # "Will this conflict?"
git merge origin/main               # Approve then merge
```

**Why this matters:**

1. **Review discipline** - Consciously decide to integrate, not automatic
2. **Conflict prevention** - Catch potential issues before merge attempt
3. **Rebase vs merge choice** - Decide per-situation (see Q2)
4. **CI/CD** - Automated systems should fetch, test, then merge

**Configuration recommendation:**
```bash
git config pull.rebase true         # Pull → rebase (linear history)
git config --global fetch.prune true  # Auto-clean deleted branches
```

Even with these, many teams discourage `git pull` in favor of explicit fetch + merge/rebase.

---

## Q7: Walk me through your branching strategy and why it works at your organization scale

**Expected Answer (Senior Level):**

**Our strategy: GitHub Flow variant**

```
main
  ↓ (always production-ready)
  
  feature branches ↓
  (short-lived, 1-3 days)
  
  ↓ PR opened
  ↓ Code review (2+ approvers if Terraform)
  ↓ CI checks pass
  ↓ Merge to main
  ↓ Auto-deploy to staging (wait 30 min)
  ↓ Production deploy gate (manual approval for prod)
```

**Why this works at our scale (8-10 person DevOps team managing 30+ dependent services):**

1. **Reduced conflict frequency**
   - Branches last 1-2 days max
   - Each developer rebases daily on main
   - 95% of merges auto-succeed

2. **Fast feedback loop**
   - Code review within hours (not days)
   - Deploy to staging same day
   - Production deployment within 24 hours
   - Enables continuous deployment (CD)

3. **Easy rollback**
   - Main always deployable
   - Revert one commit = rollback
   - No "which branch is production?" questions

4. **Team coordination minimal**
   - No dedicated role managing releases
   - No Git merge choreography meetings
   - Dev writes code → PR → merged → deployed (48 hours)

5. **New team members ramp fast**
   - Simple process (main is production)
   - No complex branching rules to learn
   - Contribute day 1-2

**Adjustments we made:**

- **Terraform changes require infrastructure team approval**
  ```
  CODEOWNERS:
    terraform/* @infrastructure-team
  ```

- **Feature flags for incomplete features**
  ```python
  if feature_flag.enabled("new-resource"):
      create_new_resource()
  ```

- **Deployment windows for production**
  ```
  Main deploys to staging immediately (always)
  Production deployment weekdays 09:00-17:00 UTC only
  ```

---

## Q8: A developer claims "Git made me lose my work." How do you investigate and what was likely the cause?

**Expected Answer (Senior Level):**

**Common causes of "lost work" and recovery:**

**1. Accident: Hard reset**
```bash
git reset --hard origin/main
# Discards all local commits and changes
Recovery:
  git reflog
  git reset --hard HEAD@{2}  # Before the reset
  Found it!
```

**2. Accident: Rebase abort mid-rebase**
```bash
git rebase main
# Conflict occurs
git rebase --abort
# They think commits are gone!
Recovery:
  git reflog
  find --hash that was HEAD during rebase
  git reset --hard <hash>
  Works!
```

**3. Force push overwrote remote**
```bash
git push --force
# Overwrote other work on remote
Recovery (as server admin):
  git reflog
  git push --force origin <old-ref>
  Recover server state
```

**4. Stash forgotten**
```bash
git stash
# Did other work, forgot about stash
Recovery:
  git stash list
  git stash pop stash@{2}
  Gets work back
```

**5. File deleted (not Git issue)**
```bash
rm important-file.tf
git add -A
git commit -m "remove file"
Recovery:
  git show HEAD~1:important-file.tf > important-file.tf
  Gets deleted file back
```

**Investigation script:**
```bash
investigate_lost_work() {
    echo "=== Investigating Lost Work ==="
    
    # Check reflog (most common recovery path)
    echo "Recent HEAD changes:"
    git reflog | head -10
    
    # Check all remote refs
    echo ""
    echo "Remote refs:"
    git show-ref --all
    
    # Check stashes
    echo ""
    echo "Stashes:"
    git stash list
    
    # Check dangling objects (orphaned commits)
    echo ""
    echo "Dangling commits:"
    git fsck --full | grep dangling
    
    # Check file history (if specific file)
    if [ -n "$1" ]; then
        echo ""
        echo "History of $1:"
        git log --all -- "$1" | head -20
        
        echo ""
        echo "Deleted versions:"
        git log --all --full-history -- "$1"
    fi
}

investigate_lost_work "filename.tf"
```

**Key teaching point:**
Git almost never loses data. Reflog keeps history for 90 days. Even "deleted" commits remain until garbage collection. The developer didn't "lose" work, they:
- Accidentally removed it locally (reset, rebase abort)
- And didn't know how to recover it
- Education: git reflog is your safety net

---

## Q9: Compare GitOps deployment model with traditional CI/CD. What are Git flow implications?

**Expected Answer (Senior Level):**

**Traditional CI/CD:**
```
git push main
  ↓
Webhook triggers CI
  ↓
Build (compile, test)
  ↓
 Artifact created
  ↓
Deploy (human approval)
  ↓
Infrastructure changed
  ↓
State: infrastructure = what we deployed
```

**GitOps:**
```
Git repo (declarative infrastructure state)
  ↓
Continuous reconciliation controller (ArgoCD, Flux)
  ↓
Constantly comparing: "Git says X, cluster is Y"
  ↓
If different: apply Git → cluster
  ↓
Monitoring: detect drift (cluster manual changes)
  ↓
State: Git = desired infrastructure (automation enforces)
```

**Git flow implications:**

**Traditional CI/CD advantages:**
- Git just for code delivery
- Deployment logic separate (Jenkins config, deploy scripts)
- No requirement that main always be deployable
- Can work with any branching model

**GitOps advantages:**
- Git IS the control plane
- Every Git commit = infrastructure change (auditable)
- Main must ALWAYS be deployable (non-negotiable)
- Automatic drift detection (cluster != Git = alert)
- True disaster recovery (Git commit = rebuild infrastructure)

**Git workflow must change for GitOps:**

```
Before GitOps:
  feature branch ← PR ← Code review ← Merge
  (Infrastructure state exists only after deployment)

After GitOps:
  feature branch ← PR ← Code review + INFRASTRUCTURE VALIDATION ← Merge
  Infrastructure state NOW IN GIT
  (Merge to main = immediate cluster changes via controller)
```

**Critical implications:**
1. **Safety threshold higher**
   - Manual deploy: Can test first, then decide to deploy
   - GitOps: Merge = automatic deployment (no approval step)
   - Requires: automated validation, human code review, staging test

2. **Branching strategy must change**
   - Main MUST be always deployable (non-optional)
   - Trunk-based development strongly recommended
   - Long feature branches risky (cluster diverges if main never deploys)

3. **Emergency procedures different**
   - Fast rollback: revert commit, PR merge, auto-deploy (minutes)
   - No "deploy" step (already happened)
   - Requires: tight integration between Git and cluster

4. **Audit trail is complete**
   - Every infrastructure change: Git commit + sign-off
   - Drift (manual cluster changes) detected and alerted
   - Compliance: "Prove who deployed what" = git log

**Example ArgoCD configuration:**
```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: infrastructure
spec:
  source:
    repoURL: https://github.com/company/infrastructure.git
    path: terraform/
    targetRevision: main        # GitOps watches main
  destination:
    server: https://kubernetes.default.svc
  syncPolicy:
    automated:
      prune: true              # Remove if not in Git
      selfHeal: true           # Reconcile if cluster changed
```

When this config runs:
1. Main branch changed (new commit)
2. ArgoCD detects change
3. Terraform applied from main
4. Cluster now reflects Git state
5. All automatic, Git-driven

---

## Q10: Design a Git workflow for a team transitioning from manual deployments to automated CI/CD with GitOps

**Expected Answer (Senior Level):**

**Current state:** Manual deployments, developers run deploy scripts, rollbacks slow

**Desired state:** GitOps, Git commits trigger deployments, auditability, disaster recovery

**3-phase transition:**

### Phase 1: Prepare (2 weeks)

**Goal:** Set up infrastructure for GitOps without changing workflows yet

```
1. Infrastructure repo setup
   - Organize Terraform/Kubernetes for GitOps
   - Ensure all infrastructure defined-as-code
   - Encrypt secrets (Vault, SOPS, aws-secrets)
   - Test TF modules locally

2. CI pipeline setup
   - Branch protection on main
   - Require code review (2 approvers)
   - Automated tests (TF validate, K8s validate)
   - Staging deployment (manual trigger)

3. Tooling setup
   - ArgoCD or Flux installed in cluster
   - Git token created (read-only for ArgoCD)
   - Monitoring for drift detection
   - Rollback procedures documented
```

**Git strategy (Phase 1):**
- Main = production (not changing yet, just protected)
- Feature branches continue as before
- Merge to main = manual deploy (traditional)
- This allows: testing everything works before automating

### Phase 2: Automate non-production (2-3 weeks)

**Goal:** Deploy dev/staging automatically from Git, keep production manual

```
1. Staging automation
   - Merge to main ← automatically deploys to staging
   - Wait 30 minutes for smoke tests
   - Team can validate in staging
   - Production: still manual

2. Monitoring + rollback
   - ArgoCD shows: Git vs actual state
   - Alert if: cluster != Git (drift)
   - Rollback: revert commit, re-merge (auto-deploy)

3. Education
   - Team writes commits in main (production ready)
   - Feel the power: "Merge = deployed to staging"
   - Practice: commit → deploy → verify → rollback
```

**Git modifications:**
```
Staging auto-deploy:
  - Main branch change ← ArgoCD detects
  - Kubectl apply staging/namespace
  ← deployed in 5 minutes
  
Production manual:
  - Staging validated
  - Manual approval: merge staging → prod-deployment PR
  - Merge to prod branch = production deployed
```

### Phase 3: Full GitOps (1-2 weeks)

**Goal:** All deployments from Git, complete automation

```
1. Production automation
   - Main now controls production
   - Change = automatic deployment
   - Requires: team comfortable with change velocity

2. Workflow changes
   - Developers: commit → review → merge
   - Automation: merge → test → deploy
   - Deploy gate: automated tests (no human "deploy" action)

3. Safety mechanisms
   - Deployment windows (business hours only)
   - Progressive deployment (canary 10% → 50% → 100%)
   - Automated rollback (if metrics degrade)
   - Communication: deploy notifications to stakeholders
```

**Integration checklist:**

```yaml
Phase 1 (Complete):
  ✓ Infrastructure-as-code defined
  ✓ ArgoCD/Flux installed
  ✓ Git repo organized correctly
  ✓ Branch protection enforced
  ✓ Manual deployment tested from Git

Phase 2 (Staging auto-deploy):
  ✓ Staging ArgoCD app created
  ✓ Auto-sync on main change
  ✓ Team validated in staging 10 times
  ✓ Rollback procedure documented and practiced
  ✓ Monitoring alerts working

Phase 3 (Production auto-deploy):
  ✓ Production ArgoCD app created
  ✓ Deployment window configured
  ✓ OnCall team trained
  ✓ Emergency procedures rehearsed
  ✓ Monitoring for drift, failures
  ✓ Go/no-go decision: team consensus
  ✓ Communication plan: keep stakeholders informed
```

**Git workflow during transition:**

```
Week 1-2 (Phase 1):
  main (protected) ← feature branches
  Deploy: Manual from main

Week 3-5 (Phase 2):
  main (protected) ← feature branches
  Deploy to staging: Automatic on main merge
  Deploy to prod: Manual from prod branch

Week 6-8 (Phase 3):
  main (protected) ← feature branches
  Deploy to staging: Automatic on main merge
  Deploy to prod: Automatic on main merge
  All orchestrated by ArgoCD from Git
```

**Recovery procedures essential before Phase 3:**

```bash
# Developers MUST practice these before full GitOps:

1. Normal rollback
   git revert bad-commit
   git push
   # ArgoCD auto-deploys revert (1-2 min)

2. Emergency revert
   git reset --hard good-commit
   git push --force
   # Cluster reverts immediately

3. Cluster drift fix
   ArgoCD manual sync button
   Or: kubectl apply latest from Git

4. Complete disaster
   git reset to tag v1.2.3
   Git becomes source of truth
   Cluster rebuilt from scratch if needed
```

---

**Document Version:** 4.0 (Final)  
**Last Updated:** March 18, 2026  
**Total Study Guide:** 4 parts, ~25,000+ words, 60+ code examples, 50+ diagrams  
**Target Audience:** Senior DevOps Engineers (5-10+ years experience)  
**Complete Coverage:** All 8 subtopics with practical enterprise scenarios and technical depth
