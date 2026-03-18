# Git Advanced: Merging, Rebasing, Remote Operations & Release Management
## Senior DevOps Engineering Study Guide - Part 3

---

## Table of Contents

1. [Merging Concepts - Advanced](#merging-concepts-advanced)
2. [Rebasing and History Management - Production Patterns](#rebasing-and-history-management-production)
3. [Remote Repository Operations - Distributed Systems](#remote-repository-operations)
4. [Tags & Release Management - Enterprise Practices](#tags--release-management-enterprise)

---

## Merging Concepts - Advanced

### Textual Deep Dive: Three-Way Merge Algorithms & Conflict Resolution at Scale

#### Internal Working Mechanism

**Three-Way Merge Algorithm (Recursive Strategy)**

```
Core Principle: Compare three versions to find what changed

Inputs:
  1. Current (HEAD):    Base branch version (e.g., main)
  2. Target (branch):   Feature branch version
  3. Common Ancestor:   Last shared commit before divergence

Algorithm Steps:

Step 1: Find Common Ancestor (merge-base)
  $ git merge-base main feature
  abc123d  (last common commit)

Step 2: Generate Diffs
  diff1 = diff(common, current)    # Changes on main since divergence
  diff2 = diff(common, target)     # Changes on feature since divergence

Step 3: Apply Non-conflicting Changes
  For each changed line:
    - If changed only in current: Accept current
    - If changed only in target: Accept target
    - If changed identically in both: Accept (no conflict)
    - If changed differently: CONFLICT

Step 4: Mark Conflicts
  <<<<<<< HEAD             # Current version
  our changes
  =======                  # Separator
  their changes
  >>>>>>> feature_name     # Target version

Visual Example:

Common Ancestor (commit abc123d):
  Line1: server_count = 3
  Line2: instance_type = "t2.micro"
  Line3: tags = {}

Current (main):
  Line1: server_count = 3       # No change
  Line2: instance_type = "t2.small"  # Changed
  Line3: tags = { env = "prod" }    # Changed

Target (feature):
  Line1: server_count = 5       # Changed ← DIFFERENT
  Line2: instance_type = "t2.micro"  # No change
  Line3: tags = {}              # No change

Auto-merge result:
  Line1: server_count = 5       # Conflict (both changed differently)
  Line2: instance_type = "t2.small"  # Accept current's change
  Line3: tags = { env = "prod" }     # Accept current's change

Resolution required: Choose server_count value
```

**Handling Binary File Conflicts**

```
Problem: Binary files can't be text-merged

Detection:
  git merge feature  (on binary file)
  # Cannot auto-merge (binary file)
  # Both added: image.png
  # Both modified: database.dump

Solutions:

1. Accept one or other
  git checkout --ours image.png    # Keep current version
  git add image.png
  
  git checkout --theirs backup.tar.gz  # Use incoming version
  git add backup.tar.gz

2. Custom merge driver
  # .gitattributes
  *.png merge=ours          # Always use current
  *.dump merge=custom-script

  # Configure script
  git config merge.custom-script.driver "python merge_dumps.py %O %A %B"
  %O = common ancestor
  %A = current (ours)
  %B = target (theirs)

3. Manual resolution outside Git
  # Extract versions, decide manually
  git show :1:image.png > image.png.ancestor
  git show :2:image.png > image.png.ours
  git show :3:image.png > image.png.theirs
  
  # Edit in external tool
  # Copy resolved version back
  cp image.png.resolved image.png
  git add image.png
```

#### Architecture Role in Large-Scale DevOps

```
Critical Decision Point in CI/CD Pipelines

Pipeline Flow:
  Feature branch pushed
    ↓
  Automated tests run
    ↓
  Code review starts
    ↓
  MERGE: Automatic or manual?
    ↓
  Deploy to staging
    ↓
  Production deployment

Merge Strategy Impact:

Fast-forward merge:
  ✓ Fast (just move pointer)
  ✓ Clean history (linear)
  ✗ Loses feature context
  ✗ Hard to track which commits shipped together

Three-way merge:
  ✓ Preserves feature context
  ✓ Shows integration point
  ✓ Better for audit trail
  ✗ Creates merge commits (clutter)
  ✗ Can mask problematic integrations

Infrastructure as Code (Terraform) example:

Feature branch modifies:
  terraform/aws/vpc.tf      # VPC configuration
  terraform/aws/security.tf # Security groups

Main branch modifies:
  terraform/aws/vpc.tf      # Different VPC settings
  terraform/aws/rds.tf      # RDS configuration

Merge behavior:
  vpc.tf: Conflicts (both modified)
  security.tf: Auto-merge (only feature touched)
  rds.tf: Auto-merge (only main touched)

Result: Must manually resolve vpc.tf
  - Ensure terraform validate passes
  - Ensure terraform plan shows expected changes
  - Requires infrastructure understanding (not just Git)
```

#### DevOps Best Practices for Conflict Resolution

```
Principle 1: Automated Conflict Prevention

Strategy:
  1. Keep feature branches short-lived (< 2 days)
  2. Frequently rebase on main (daily)
     git fetch origin
     git rebase origin/main
  3. This catches conflicts early, not at merge time

  Benefit: Conflicts resolved by feature developer
          (understands their change vs. main's new features)

Principle 2: Infrastructure Testing Before Merge

Script: test-merge.sh
  #!/bin/bash
  set -e
  
  FEATURE_BRANCH=$1
  
  # Create temporary branch for merge test
  git checkout -b merge-test origin/main
  
  # Attempt merge
  if ! git merge --no-commit --no-ff "$FEATURE_BRANCH"; then
    echo "❌ Merge conflicts detected"
    git merge --abort
    exit 1
  fi
  
  # Test merged infrastructure
  echo "Testing merged infrastructure..."
  
  if ! terraform validate terraform/; then
    echo "❌ Terraform validation failed"
    git merge --abort
    exit 1
  fi
  
  if ! terraform plan terraform/ > /tmp/plan.txt; then
    echo "❌ Terraform plan failed"
    git merge --abort
    exit 1
  fi
  
  # Check for expected changes
  if grep -q "Plan: 0 to add, 0 to change, 0 to destroy" /tmp/plan.txt; then
    echo "⚠️ No infrastructure changes detected"
  fi
  
  echo "✅ Merge test passed"
  git merge --abort  # Don't actually commit
  
  Usage:
    ./test-merge.sh feature/add-monitoring

Principle 3: Conflict Resolution Strategy by File Type

  Terraform files (.tf):
    - Manual review required
    - Test terraform plan
    - Coordinate with infrastructure team
  
  YAML manifests (k8s):
    - kubeval validation
    - May have conflicts in spec duplicates
    - Test with kubectl apply --dry-run
  
  Config files (non-code):
    - Often merge cleanly
    - Review user-facing changes
  
  Source code:
    - Standard three-way merge
    - Tests must pass
    - Code review addresses logic errors

Principle 4: Communication During Merge Conflicts

  Team Checklist:
    ✓ Owner of each conflicting file notified
    ✓ Sync call if > 5 conflicts
    ✓ Decision logged (who decided what, why)
    ✓ Tests run before merge commit
    ✓ Post-merge rollback plan documented

  Slack Notification:
    @alice @bob: Merge conflict in terraform/vpc.tf
    PR: #423
    Branches: feature/multi-region vs. main
    Action: Requires manual resolution
    Link: [Review Conflict]
```

#### Common Pitfalls

**Pitfall 1: Inadequate Testing After Merge**

```
Problem:
  Conflicts resolved manually → Merged → Tests fail
  
Example:
  terraform/main.tf resolved conflict
  Merged to main → CI tests pass (basic checks)
  Deployed to staging → Infrastructure deploy fails (semantic error)
  
Prevention:
  1. Run integration tests before merge
  2. Infrastructure tests (terraform apply -plan)
  3. Team review of complex merges
  4. Stage deployment validation
  
  Script: pre-merge-validation.sh
    #!/bin/bash
    
    echo "Pre-merge validation for $1"
    
    # Checkout feature branch
    git checkout "$1"
    
    # Pull latest main
    git fetch origin main
    
    # Create test branch
    git checkout -b test-merge
    
    # Test merge
    if ! git merge --no-commit origin/main; then
      echo "Merge has conflicts - resolve first"
      git merge --abort
      exit 1
    fi
    
    # Run comprehensive tests
    echo "Running terraform validation..."
    terraform validate -json terraform/
    
    echo "Running terraform plan..."
    terraform plan -json terraform/ > /tmp/plan.json
    
    echo "Checking for resource deletions..."
    if grep -q '"delete"' /tmp/plan.json; then
      echo "⚠️ Warning: Resources will be deleted!"
      cat /tmp/plan.json | jq '.resource_changes[] | select(.change.actions[] | contains("delete"))'
      echo "Require manual confirmation before merge"
    fi
    
    # Validation done
    git merge --abort
    echo "✅ Pre-merge validation passed"
```

**Pitfall 2: Merge Conflict Markers Left in Code**

```
Problem:
  Developer resolves conflicts but leaves markers:
    <<<<<<< HEAD
    =======
    >>>>>>> feature
  
  This causes:
    - Syntax errors
    - Terraform validation fails
    - Tests don't catch this (not compiled/validated post-merge)

Prevention:
  Pre-commit hook to catch leftover markers:
    #!/bin/bash
    # .git/hooks/pre-commit
    
    CONFLICTED=$(git diff --cached --name-only)
    
    for file in $CONFLICTED; do
      if grep -l "<<<<<<< HEAD\|=======" "$file" 2>/dev/null; then
        echo "❌ Conflict markers found in: $file"
        exit 1
      fi
    done

  Alternative tool:
    $ git ls-files --unmerged  # Check for unmerged files
```

**Pitfall 3: Incorrect Resolution of Multi-File Conflicts**

```
Scenario:
  Team A: Adds new infrastructure resource
  Team B: Refactors module structure
  
  Conflicts in:
    variables.tf (variable definition moved)
    outputs.tf (output reference changed)
    main.tf (resource location changed)
  
  Manual resolution picks wrong version for each file
  Result: References broken across files

Prevention:
  Understanding semantic relationships:
  
  $ git show MERGE_HEAD  # See what we're merging
  
  # Check what main has added
  $ git diff --name-only main...MERGE_HEAD
  
  # Understand conflict sources
  $ git log --oneline -5 MERGE_HEAD  # Feature branch commits
  $ git log --oneline -5 main        # Main branch commits
  
  Resolution strategy:
    1. Understand each branch's intent (review commits)
    2. Resolve file by file
    3. Test after each resolution
    4. Run full test before marking resolved
```

---

### Practical Code Examples: Merge Resolution Workflows

**Example 1: Automatic Merge Conflict Detection & Resolution**

```bash
#!/bin/bash
# merge-conflict-handler.sh
# Detect, report, and provide resolution guidance for merge conflicts

set -e

FEATURE_BRANCH=${1:?Usage: $0 <feature-branch>}
TARGET_BRANCH=${2:-main}

echo "=== Git Merge Conflict Handler ==="
echo "Feature: $FEATURE_BRANCH"
echo "Target: $TARGET_BRANCH"
echo ""

# Ensure branches exist
git fetch origin || true
if ! git rev-parse --verify "origin/$FEATURE_BRANCH" > /dev/null 2>&1; then
    echo "❌ Branch not found: origin/$FEATURE_BRANCH"
    exit 1
fi

# Create temporary merge branch
TEMP_BRANCH="merge-test-$$"
git checkout -b "$TEMP_BRANCH" "origin/$TARGET_BRANCH"

# Attempt merge (non-destructive)
echo "Attempting merge..."
if git merge --no-commit --no-ff "origin/$FEATURE_BRANCH" 2>/dev/null; then
    echo "✅ Merge successful (no conflicts)"
    git merge --abort
    rm -f "$TEMP_BRANCH"
    exit 0
fi

# Conflicts detected
echo "⚠️ Merge conflicts detected"
echo ""

# List conflicted files
echo "Conflicted files:"
CONFLICTED=$(git diff --name-only --diff-filter=U)
echo "$CONFLICTED" | nl

# Detailed conflict analysis
echo ""
echo "=== Conflict Details ==="
for file in $CONFLICTED; do
    echo ""
    echo "File: $file"
    echo "Lines with conflicts:"
    
    # Count conflicts
    CONFLICT_COUNT=$(grep -c "<<<<<<< HEAD" "$file" || true)
    echo "  Conflict sections: $CONFLICT_COUNT"
    
    # Show conflict context
    grep -n "<<<<<<< HEAD" "$file" | while read -r line; do
        LINENUM=$(echo "$line" | cut -d: -f1)
        echo "  - Around line $LINENUM"
    done
    
    # Determine file type
    if [[ "$file" == *.tf ]]; then
        echo "  Type: Terraform - Requires manual resolution + terraform validate"
    elif [[ "$file" == *.yaml ]] || [[ "$file" == *.yml ]]; then
        echo "  Type: YAML - Requires manual resolution + schema validation"
    elif [[ "$file" == *.py ]]; then
        echo "  Type: Python - Requires manual resolution + syntax check"
    else
        echo "  Type: Other"
    fi
done

# Resolution suggestions
echo ""
echo "=== Resolution Options ==="
echo ""
echo "Option 1: Interactive merge tool"
echo "  git mergetool"
echo ""
echo "Option 2: Accept one version"
for file in $CONFLICTED; do
    echo "  # Accept current (main):"
    echo "  git checkout --ours $file"
    echo "  # Accept feature:"
    echo "  git checkout --theirs $file"
done
echo ""
echo "Option 3: Manual resolution"
echo "  Edit files manually, then:"
for file in $CONFLICTED; do
    echo "  git add $file"
done
echo "  git commit -m 'merge: resolve conflicts'"
echo ""

# Cleanup and abort
git merge --abort
git checkout - > /dev/null 2>&1 || git checkout "$TARGET_BRANCH" > /dev/null 2>&1
git branch -D "$TEMP_BRANCH" 2>/dev/null || true

echo "=== To proceed with actual merge ==="
echo "  git checkout -b feature/$FEATURE_BRANCH origin/$FEATURE_BRANCH"
echo "  git merge origin/$TARGET_BRANCH"
echo "  # Resolve conflicts"
echo "  git add ."
echo "  git commit -m 'merge: resolve conflicts with main'"
echo "  git push origin feature/$FEATURE_BRANCH"
```

**Example 2: Three-Way Merge with Testing**

```bash
#!/bin/bash
# merge-with-testing.sh
# Perform merge and run comprehensive tests

FEATURE_BRANCH=${1:?Usage: $0 <feature-branch>}
TARGET=${2:-main}

set -e

echo "=== Merge with Testing ==="

# Create test branch
git fetch origin
TEST_BRANCH="test-merge-$$-$(date +%s)"
git checkout -b "$TEST_BRANCH" "origin/$TARGET"

# Perform merge
if ! git merge --no-commit "origin/$FEATURE_BRANCH"; then
    echo "❌ Merge conflicts - manual resolution required"
    git merge --abort
    git checkout "$TARGET"
    git branch -D "$TEST_BRANCH"
    exit 1
fi

echo "✅ Merge completed without conflicts"
echo ""

# Run tests
SUCCESS=true

# Test 1: Terraform validation
if [ -d terraform ]; then
    echo "Test 1: Terraform validation..."
    if terraform validate terraform/ > /dev/null 2>&1; then
        echo "  ✅ Terraform validation passed"
    else
        echo "  ❌ Terraform validation failed"
        terraform validate terraform/ || true
        SUCCESS=false
    fi
fi

# Test 2: Terraform plan
if [ -d terraform ]; then
    echo "Test 2: Terraform plan..."
    if terraform plan terraform/ -json > /tmp/plan.json 2>&1; then
        echo "  ✅ Terraform plan succeeded"
        
        # Check for resource deletions
        if grep -q '"delete"' /tmp/plan.json; then
            echo "  ⚠️ WARNING: This merge will delete resources!"
            jq '.resource_changes[] | select(.change.actions[] | contains("delete"))' /tmp/plan.json
        fi
    else
        echo "  ❌ Terraform plan failed"
        SUCCESS=false
    fi
fi

# Test 3: Kubernetes manifests
if [ -d kubernetes ]; then
    echo "Test 3: Kubernetes validation..."
    find kubernetes -name "*.yaml" -o -name "*.yml" | while read -r manifest; do
        if ! kubeval "$manifest" > /dev/null 2>&1; then
            echo "  ❌ Invalid manifest: $manifest"
            SUCCESS=false
        fi
    done
    if [ "$SUCCESS" = true ]; then
        echo "  ✅ All Kubernetes manifests valid"
    fi
fi

# Test 4: Script syntax
if [ -d scripts ]; then
    echo "Test 4: Script syntax..."
    find scripts -name "*.sh" | while read -r script; do
        if ! bash -n "$script" 2>/dev/null; then
            echo "  ❌ Syntax error: $script"
            SUCCESS=false
        fi
    done
    if [ "$SUCCESS" = true ]; then
        echo "  ✅ All scripts valid"
    fi
fi

# Results
echo ""
if [ "$SUCCESS" = true ]; then
    echo "✅ All tests passed - Merge is safe"
    git commit --no-edit
    echo ""
    echo "Merge committed to $TEST_BRANCH"
    echo "To finalize:"
    echo "  git checkout $TARGET"
    echo "  git merge $TEST_BRANCH"
    echo "  git push origin $TARGET"
else
    echo "❌ Tests failed - Merge aborted"
    git merge --abort
fi

# Cleanup
git checkout "$TARGET" 2>/dev/null || true
git branch -D "$TEST_BRANCH"
```

---

### ASCII Diagrams: Merge Scenarios

**Diagram 1: Three-Way Merge Conflict Resolution**

```
Common Ancestor (shared history point):
┌─────────────────────────────────────────┐
│ resource "aws_instance" "app" {         │
│   count = 3                             │
│   instance_type = "t2.micro"            │
│ }                                       │
└─────────────────────────────────────────┘

                 │
        ┌────────┴────────┐
        │                 │
        ▼                 ▼

Current (main):          Target (feature):
┌──────────────┐        ┌──────────────┐
│ count = 3    │        │ count = 5    │ ← CONFLICT
│ type =       │        │ type =       │
│ t2.small     │        │ t2.micro     │ ← CONFLICT
│ tags = {}    │        │ tags = {}    │ (unchanged)
└──────────────┘        └──────────────┘

Merge conflict markers:
  <<<<<<< HEAD
  count = 3
  instance_type = "t2.small"
  =======
  count = 5
  instance_type = "t2.micro"
  >>>>>>> feature

Resolution decision matrix:
┌──────────────────┬──────────────┬─────────────┐
│ Field            │ Current      │ Feature     │
├──────────────────┼──────────────┼─────────────┤
│ count            │ 3            │ 5 ← CHOOSE  │
│ instance_type    │ t2.small ←   │ t2.micro    │
│ tags             │ {} (both)    │ {} (both)   │
└──────────────────┴──────────────┴─────────────┘

Result after resolution:
  count = 5              (chose feature's scale-up)
  instance_type = t2.small  (chose main's upgrade)
  tags = {}              (same in both)
```

**Diagram 2: Multi-Branch Merge Conflict Flow**

```
Repository State:

main ────► A ──► B ──► C ──────────► E (merge commit)
                 │                  ▲
                 └──────┬───────────┘
                        │
         feature ──► D ─┘
         
         develop ──► F ──► G

Merge Process:

Step 1: Checkout main
  HEAD → main (C)

Step 2: Merge feature
  git merge feature
  
  Three-way comparison:
    Common ancestor: B
    Current (HEAD): C
    Target: D
    
  If C and D both modified same files:
    → Conflict!

Step 3: Resolve conflicts
  Manually edit files
  Choose versions or combine

Step 4: Commit merge
  git commit -m "merge: ..."
  Creates E with parents C, D

Result:
main ────► A ──► B ──► C ──────► E (merge commit)
                 │              ▲ └─ merge parent
                 └──► D ────────┘
                      (feature changes)

History graph (git log --graph):
  * E (main) - Merge branch feature into main
  |\
  | * D (feature) - Feature work
  * | C - Main work
  |/
  * B - Common ancestor
  * A - Initial commit
```

**Diagram 3: Merge Conflict Resolution Workflow**

```
Developer pushes feature
         ↓
Automated tests run
         ↓
Code review starts
         ↓
Merge attempt initiated
         ↓
    ┌──────────────────┐
    │ Conflicts?       │
    └────────┬─────────┘
             │
       ┌─────┴─────┐
       │           │
      No           Yes
       │            │
       ▼            ▼
    Auto-     ┌──────────────────┐
    merge     │ Conflict Report: │
    OK        │ - Files affected │
       │      │ - Type info      │
       │      │ - Suggestions    │
       │      └──────┬───────────┘
       │             │
       │             ▼
       │      ┌──────────────────┐
       │      │ Team Review      │
       │      │ Semantic check   │
       │      └──────┬───────────┘
       │             │
       │             ▼
       │      ┌──────────────────┐
       │      │ Manual           │
       │      │ Resolution       │
       │      └──────┬───────────┘
       │             │
       │             ▼
       │      ┌──────────────────┐
       │      │ Test merged      │
       │      │ infrastructure   │
       │      └──────┬───────────┘
       │             │
       └─────────┬───┘
                 │
                 ▼
        ┌─────────────────┐
        │ Merge commit    │
        │ ready           │
        └────────┬────────┘
                 │
                 ▼
        ┌─────────────────┐
        │ Deploy to       │
        │ staging         │
        └─────────────────┘
```

---

## Rebasing and History Management - Production

### Textual Deep Dive: Interactive Rebase in Enterprise Environments

#### Internal Working Mechanism: Rebase Under the Hood

```
Rebase mechanism: Cherry-pick commits onto new base

Simple rebase example:

Before:
  main → A ──► B ──► C
            ↗ feature ──► D ──► E

Command:
  git rebase main feature

Process:
  1. Identify base (main = head C)
  2. Find commits in feature not in main (D, E)
  3. Resolve conflicts (if any)
  4. Apply D on top of C → create D' (new commit)
  5. Apply E on top of D' → create E' (new commit)
  6. Move feature pointer to E'

After:
  main → A ──► B ──► C
             ↗ D' ──► E' (feature)

New commits D', E':
  - Same changes as D, E
  - Different parent (C instead of B)
  - Different hash (contains parent info)
  - Old D, E become orphaned (recovery via reflog)

Commit hash components:
  Old D: hash(content + parent=B)
  New D': hash(content + parent=C)
  
  Even though content identical, hashes differ
  (hash includes parent reference)
```

**Interactive Rebase Operations**

```
git rebase -i HEAD~5          # Rebase last 5 commits

Interactive editor opens:
  pick abc123 Commit message 1
  pick def456 Commit message 2
  pick ghi789 Commit message 3
  pick jkl012 Commit message 4
  pick mno345 Commit message 5

Available commands:
  p (pick): Use commit as-is
  r (reword): Use commit, edit message
  e (edit): Stop to amend this commit
  s (squash): Use commit, combine with previous
  f (fixup): Like squash, but discard message
  d (drop): Remove commit
  x (exec): Run shell command
  b (break): Stop point
  l (label): Name a commit
  t (reset): Reset to label
  m (merge): Create merge commit

Execution shows conflicts as they occur
  Can resolve during rebase process
  --continue after resolving
  --abort to cancel
```

#### Architecture Role: History Rewriting for Compliance

```
Why DevOps teams rewrite history:

1. Clean commit history for auditing
   - Squash WIP commits
   - Remove temporary test commits
   - Only meaningful changes in log

2. Compliance requirements
   - Must trace every infrastructure change
   - Clean history aids investigation
   - Audit trail cannot show accidental pushes

3. Debugging efficiency
   - git blame on clean commits is meaningful
   - History shows intentional changes
   - Bisection finds issues faster

Infrastructure repository example:

Branch with 20 commits:
  commit 1: WIP: add variables
  commit 2: WIP: add vpc resource
  commit 3: typofixed
  commit 4: forgot to add security group
  commit 5: WIP: testing iam policy
  commit 6: fix iam policy (for real)
  commit 7: final infrastructure
  ...etc...

After interactive rebase (should be 1-2 commits):
  commit 1: feat: add VPC with security groups and IAM
  commit 2: fix: correct IAM policy permissions

Benefits:
  - Readable log
  - Easier blame investigation
  - Cleaner merge commit
  - Better for release notes
```

#### DevOps Best Practices

**Practice 1: Rebase Workflow in Release Branches**

```
Git Flow variant for infrastructure:

Main branch: Production code (absolute requirements)
  - Fully tested
  - Fully reviewed
  - Must merge, not rebase
  - Every commit deployable

Release branches: Release prep
  - Rebase allowed (cleanup)
  - Version bump commits
  - Changelog updates
  - Squash test commits

Feature branches: Development
  - Rebase encouraged (local cleanup)
  - Interactive rebase before PR
  - Squash WIP commits
  - Clean up commit messages

Implementation:

  # Developer work on feature
  git checkout -b feature/monitoring
  # ... many commits, some WIP ...
  git commit -m "WIP: prometheus setup"
  git commit -m "typo fix"
  git commit -m "feat: add monitoring stack"
  
  # Before pushing to PR
  git rebase -i origin/main
  # Squash WIP commits
  # Reword final commit
  
  # Push clean history
  git push origin feature/monitoring
  
  # Result: 1-2 clean commits instead of 5 messy ones

Practice 2: Scheduled Cleanup Rebases

Strategy: Monthly repository history cleanup

Script: cleanup-history.sh
  #!/bin/bash
  # Quarterly history cleanup for old branches
  
  set -e
  
  BEFORE_DATE="6 months ago"
  
  echo "Finding old branches..."
  
  # List branches older than threshold
  OLD_BRANCHES=$(git for-each-ref \
    --sort=committerdate \
    --format='%(refname:short) %(committerdate:short)' \
    refs/remotes/origin | \
    awk -v cutoff="$(date -d "$BEFORE_DATE" +%Y-%m-%d)" \
    '$2 < cutoff {print $1}' | \
    grep -v main | grep -v develop)
  
  if [ -z "$OLD_BRANCHES" ]; then
    echo "✅ No old branches to clean"
    exit 0
  fi
  
  echo "Old branches (> 6 months):"
  echo "$OLD_BRANCHES"
  echo ""
  echo "These branches can be safely deleted:"
  
  for branch in $OLD_BRANCHES; do
    # Check if merged
    if git merge-base --is-ancestor "$branch" main; then
      echo "  $branch (already merged)"
      git push origin --delete "${branch#origin/}" || true
    else
      echo "  ⚠️  $branch (not merged, keeping)"
    fi
  done
  
  echo ""
  echo "Running garbage collection..."
  git gc --aggressive
```

#### Common Pitfalls

**Pitfall 1: Rebasing Shared Branch**

```
Problem:
  Developer A: Rebases main locally
  Developer B: Already has old main
  Developer A: git push --force (overwrites remote)
  Result: Developer B's commits orphaned

Prevention:
  git config branch.main.pushRemote ""  # Prevent pushing to main
  
  Or:
  git config receive.denyNonFastForwards true  # Server-side

Recovery if happens:
  Developer B:
    git fetch origin
    git reflog  # Find old main ref
    git reset --hard HEAD@{1}  # Restore old state

Lesson: Never rebase shared branches unless coordinated
```

**Pitfall 2: Rebase Conflicts During Interactive Rebase**

```
Scenario:
  git rebase -i HEAD~10  # Rebase last 10 commits
  
  Rebase in progress:
    Rebasing 10 commits...
    Conflict on commit 5 of 10
    Cannot continue (files in conflict state)

Problem: What now?

Options:

1. Fix and continue
  # Edit conflicted files
  git add .
  git rebase --continue
  # Rebase continues to next commit

2. Skip this commit
  git rebase --skip
  # Move to next commit (lose this commit's changes)

3. Abort rebase
  git rebase --abort
  # Return to state before rebase
  # Original commits intact

Safety: Always have exit strategy
  git reflog  # Find pre-rebase HEAD
  git reset --hard HEAD@{1}  # Return to before rebase
```

---

### Practical Code Examples: Advanced Rebasing

**Example 1: Interactive Rebase with Automated Squashing**

```bash
#!/bin/bash
# interactive-rebase-template.sh
# Create template for interactive rebase with suggested operations

BRANCH=${1:-HEAD~5}

echo "=== Interactive Rebase Suggestions ==="
echo ""
echo "Analyzing commits in: $BRANCH"
echo ""

# Get commits
COMMITS=$(git rev-list --oneline "$BRANCH" | tac)

echo "Current commits:"
echo "$COMMITS" | nl
echo ""

# Analyze each commit
echo "=== Analysis ==="
while IFS= read -r commit; do
    HASH=$(echo "$commit" | awk '{print $1}')
    MSG=$(echo "$commit" | cut -d' ' -f2-)
    
    # Check if likely WIP
    if [[ "$MSG" =~ ^[Ww][Ii][Pp] ]] || \
       [[ "$MSG" =~ typo ]] || \
       [[ "$MSG" =~ fix: ]] && [[ "$MSG" =~ again ]]; then
        echo "  $HASH - $MSG → CANDIDATE FOR SQUASH"
    else
        echo "  $HASH - $MSG → KEEP (pick)"
    fi
done <<< "$(echo "$COMMITS" | tac)"

echo ""
echo "=== Suggested rebase script ==="
echo ""
echo "git rebase -i $BRANCH"
echo ""
echo "In editor, make these changes:"
COUNT=0
while IFS= read -r commit; do
    MSG=$(echo "$commit" | cut -d' ' -f2-)
    if [[ "$MSG" =~ ^[Ww][Ii][Pp] ]]; then
        if [ $COUNT -eq 0 ]; then
            echo "  (first line: keep 'pick')"
        else
            echo "  (line $((COUNT+1)): change 'pick' to 'squash')"
        fi
    fi
    COUNT=$((COUNT+1))
done <<< "$(echo "$COMMITS" | tac)"
```

**Example 2: Rebase with Testing**

```bash
#!/bin/bash
# rebase-with-validation.sh
# Rebase and validate after each commit

ONTO_BRANCH=${1:?Usage: $0 <branch-to-rebase-onto>}

set -e

echo "=== Rebase with Validation ==="
echo "Rebasing onto: $ONTO_BRANCH"
echo ""

# Get commits to rebase
COMMITS=$(git rev-list "$ONTO_BRANCH"..HEAD | tac)
TOTAL=$(echo "$COMMITS" | wc -l)
COUNT=0

# Create rebase script
REBASE_SCRIPT="/tmp/rebase-validate-$$"
cat > "$REBASE_SCRIPT" << 'EOF'
#!/bin/bash

# This script runs after each commit during rebase
# Validates infrastructure after each commit

set -e

# Only test on actual commits, not merge commits
if [ "$GIT_REBASE_MODE" = "exec" ]; then
    echo "Validating..."
    
    # Test 1: Terraform
    if [ -d terraform ]; then
        terraform validate terraform/ || exit 1
    fi
    
    # Test 2: Kubernetes
    if [ -d kubernetes ]; then
        kubeval kubernetes/*.yaml || exit 1
    fi
    
    echo "✅ Validation passed for $(git rev-parse --short HEAD)"
fi
EOF

chmod +x "$REBASE_SCRIPT"

# Perform interactive rebase with validation
git rebase -i "$ONTO_BRANCH" << 'REBASE_CMDS'
# Add validation between commits
# (This would require --exec but simpler to demonstrate)
REBASE_CMDS

echo "✅ Rebase completed successfully"
rm -f "$REBASE_SCRIPT"
```

---

## Remote Repository Operations

### Textual Deep Dive: Distributed Workflows at Scale

#### Multi-Remote Repository Architecture

```
Enterprise distributed repository setup:

GitHub (Source of truth):
  origin ← primary repository
  
Azure DevOps (CI/CD): 
  trigger ← for automated builds
  
Mirror (Disaster recovery):
  /backups/infrastructure.git ← backup
  
Regional copies (Asia Pacific):
  apac-mirror ← distributed for speed
  
Staging repo (Pre-production):
  staging-repo ← for validation

Configuration:
  [remote "origin"]
    url = https://github.com/org/infrastructure.git
    fetch = +refs/heads/*:refs/remotes/origin/*
  
  [remote "upstream"]
    url = https://github.com/original/infrastructure.git
    fetch = +refs/heads/*:refs/remotes/upstream/*
  
  [remote "apac"]
    url = https://apac.mirror.company.com/infrastructure.git
    fetch = +refs/heads/*:refs/remotes/apac/*
  
  [remote "dr-backup"]
    url = file:///backups/infrastructure.git
    fetch = +refs/heads/*:refs/remotes/dr-backup/*

Operations across remotes:
  git fetch --all              # Fetch from all remotes
  git push origin main         # Push to primary
  git push --all               # Push to all configured remotes
  git log origin/main apac/main # Compare branch states
```

#### Fetch Strategies for Distributed Teams

```
Challenge: Large team across continents
  - GitHub primary: US East (100ms latency from Europe)
  - developers in European offices
  - Clone/fetch operations slow (100MB repo * 100ms = slow)

Solution: Regional Mirrors with fallback

Strategy 1: Smart fetch script
  #!/bin/bash
  # fetch-from-nearest.sh
  
  LOCATION=$(curl -s https://geoip.company.com/location | jq -r .region)
  
  case $LOCATION in
    eu-west)
      MIRROR="https://eu.mirror.company.com"
      ;;
    apac)
      MIRROR="https://apac.mirror.company.com"
      ;;
    us-east)
      MIRROR="https://github.com"
      ;;
    *)
      MIRROR="https://github.com"
      ;;
  esac
  
  git config --local remote.origin.url "$MIRROR/org/infrastructure.git"

Strategy 2: Reference-based clone (local cache)
  # First developer clones from GitHub
  git clone https://github.com/org/infrastructure.git
  
  # Subsequent developers reference local cache
  git clone --reference ~/git-cache https://github.com/org/infrastructure.git
  # Saves bandwidth (objects already local)

Strategy 3: Shallow clone + fetch deeper
  # CI/CD quick clone
  git clone --depth 1 --branch main https://github.com/org/infrastructure.git
  
  # If need history later
  git fetch --unshallow        # Fetch full history
```

#### Push Strategies and Coordination

```
Simple push (one file):
  git push origin main        # Push current branch

Complex push (multiple changes):
  Problem: Multiple commits affect multiple services
  
  Example:
    Commit 1: Update terraform module
    Commit 2: Update kubernetes manifests
    Commit 3: Update ansible playbook
    All need coordinated deployment
  
  Solution: Single push, coordinated deployment
    git push origin main      # All 3 commits pushed simultaneously
    
    Server-side hook triggers deployment:
      - Tests all changes together
      - Deploys as unit
      - Rollback is single point

Push with verification:
  #!/bin/bash
  
  # Before pushing, verify state
  if [ -n "$(git status --porcelain)" ]; then
    echo "❌ Uncommitted changes exist"
    exit 1
  fi
  
  # Verify upstream state
  git fetch origin
  if [ "$(git rev-list origin/main..HEAD | wc -l)" -gt 10 ]; then
    echo "⚠️ 10+ commits ahead of remote - unusual, verify!"
  fi
  
  # Perform push
  git push origin main
  
  # Verify push succeeded
  if ! git diff origin/main | grep -q ""; then
    echo "✅ Push verified"
  else
    echo "❌ Push verification failed"
  fi
```

#### Common Pitfalls in Distributed Workflows

**Pitfall 1: Lost Work Due to Async Pushes**

```
Scenario:
  Developer A working on feature/auth
  Also has local commits they forgot about
  
  git fetch origin
  git rebase origin/main          # Rebases feature/auth
  git push origin feature/auth    # Pushes rebased feature/auth
  
  Problem: Local commits on main that weren't pushed are lost!
  
Prevention:
  Before pushing/rebasing:
    git status                  # Check all branches
    git branch -v               # Show commits ahead/behind
    
  Safe workflow:
    for branch in $(git branch | awk '{print $NF}'); do
      echo "Branch: $branch"
      echo "  Commits: $(git rev-list --count $branch ^origin/$branch 2>/dev/null || echo 0)"
    done

Salvage if happens:
  git reflog --all            # Find lost commits
  git branch recover <lost-commit-hash>
  git cherry-pick <commit>    # Re-apply lost commits
```

**Pitfall 2: Diverged Histories**

```
Scenario:
  Repository history shows:
    main → A → B → C
              ↗ origin/main → C'
              (C and C' are different commits with same content)
  
  This creates mess on next fetch/merge

Prevention:
  # Check before pushing
  git log origin/main..main    # Commits we have
  git log main..origin/main    # Commits remote has
  
  # If diverged:
  git pull --rebase origin main
  
Alert system:
  #!/bin/bash
  # Check if histories diverged
  
  git fetch origin
  
  LOCAL=$(git rev-parse main)
  REMOTE=$(git rev-parse origin/main)
  COMMON=$(git merge-base main origin/main)
  
  if [ "$LOCAL" != "$REMOTE" ] && [ "$COMMON" != "$REMOTE" ]; then
    echo "⚠️ Diverged histories detected!"
    echo "Local: $LOCAL"
    echo "Remote: $REMOTE"
    echo "Common: $COMMON"
    echo "Run: git rebase origin/main"
    exit 1
  fi
```

---

### ASCII Diagrams: Distributed Operations

**Diagram 1: Multi-Repository Distributed Workflow**

```
GitHub Primary (GitHub-hosted):
  infrastructure/
  ├── main (latest)
  └── develop

Developer Workstation (Local):
  .git/
  ├── refs/remotes/origin → GitHub
  ├── refs/remotes/upstream → Original source
  └── refs/remotes/apac → Regional mirror

Fetch Flow:
  GitHub
    ↓ (primary fetch)
  Developer origin/
    ↓ (used by default)
  Working directory

Scenario (slow GitHub link):

Option 1: Direct from GitHub
  git fetch origin
  Time: 30 seconds (200MB * 200ms)

Option 2: Nearest mirror
  git fetch apac
  Time: 3 seconds (200MB * 15ms, low latency)
  
  Recovery to origin:
    git fetch origin
    git branch --set-upstream-to=origin/main main

Diagram:
  Internet
  
  GitHub (Primary) ────────► Developer
  100ms latency               (30s clone)
  
  APAC Mirror ─────► Developer
  15ms latency        (3s clone)
```

**Diagram 2: Push Coordination Flow**

```
Multiple developers pushing simultaneously:

Developer A        Developer B        Developer C
┌────────┐         ┌────────┐        ┌────────┐
│ 3 new  │         │ 2 new  │        │ 1 new  │
│ commits│         │ commits│        │ commit │
└────┬───┘         └────┬───┘        └────┬───┘
     │ push             │ push            │ push
     └─────────┬────────┴────────┬───────┘
               │                │
         GitHub receives:
         ┌─────────────┐
         │  3 + 2 + 1  │
         │ = 6 commits │
         │ to process  │
         └─────────────┘
               │
         CI/CD Pipeline:
         ┌─────────────────────┐
         │ Test all 6 commits  │
         │ together (not 3     │
         │ separate validations)
         │                     │
         │ Result: Single      │
         │ deployment if pass  │
         └─────────────────────┘

Timeline:
  t=0  A, B, C push simultaneously
  t=5  GitHub receives all commits
  t=10 CI pipeline starts
  t=60 All tests pass
  t=65 Deployment triggered
  t=120 Deployed successfully
  
  (vs. sequential approach: 3x longer)
```

**Diagram 3: Disaster Recovery with Mirrors**

```
Primary Failure Scenario:

GitHub Down:
  Primary: ❌ (unreachable)
  Backup:  ✅ (intact copy)

Failover Process:

Step 1: Detect primary down
  git fetch origin
  # Connection timeout or DNS error

Step 2: Switch to mirror
  git remote set-url origin /backups/infrastructure.git
  git fetch origin
  # Success! Using local backup

Step 3: Work from backup
  git push origin new-feature
  # Pushes to backup

Step 4: Primary restored (hours later)
  github.com responding again
  
Step 5: Sync backup to primary
  git remote set-url origin https://github.com/org/
  git push --mirror
  # Pushes all commits from backup to restored primary

Timeline:
  08:00 GitHub down
  08:02 Failover to backup (RPO: 0, RTO: 2 min)
  08:05 Team continues work on backup
  10:00 GitHub restored
  10:05 Sync backup to primary
  10:10 Primary and backup in sync
```

---

## Tags & Release Management - Enterprise

### Textual Deep Dive: Advanced Tagging Strategies

#### Annotated vs. Lightweight Tags in Enterprise

```
Lightweight Tag (pointer only):
  git tag v1.0.0
  
  Stored as:
    .git/refs/tags/v1.0.0 → abc123d (commit hash)
  
  Properties:
    - Very small (just a ref)
    - No metadata
    - Cannot be signed
    - Quick for temporary markers
  
  Use: Internal development, temporary marks

Annotated Tag (full object):
  git tag -a v1.0.0 -m "Release 1.0.0"
  
  Stored as:
    Object in object store (like commit)
    Contains:
      - Commit hash
      - Tagger name/email
      - Timestamp
      - Message
      - Optional GPG signature
  
  Properties:
    - Full metadata
    - Can be signed (GPG)
    - Larger (stores metadata)
    - Auditable (who, when, what)
  
  Use: Production releases, compliance

Enterprise policy recommendation:
  ALL production tags must be annotated + signed
  Development tags can be lightweight
```

**GPG Signed Tags for Audit**

```
Why sign tags:

1. Authentication: Prove who created tag
2. Non-repudiation: Cannot deny creating tag
3. Integrity: Cannot modify tag after signing (signature breaks)
4. Compliance: Meet regulatory requirements (SOC 2, HIPAA)

Setup:
  # Generate or import GPG key
  gpg --full-generate-key
  
  # Get key ID
  gpg --list-keys
  
  # Configure Git
  git config --global user.signingkey KEY_ID
  git config --global commit.gpgsign true  # Auto-sign commits

Creating signed tag:
  git tag -s v1.0.0 -m "Release 1.0.0"
  # Opens GPG dialog, enters passphrase
  # Tag created with signature

Verifying signed tag:
  git tag -v v1.0.0
  
  Output:
    object abc123def456...
    type commit
    tagger Alice Chen <alice@company.com> 1234567890
    
    Release 1.0.0
    gpg: Signature made Wed Mar 18 14:23:45 2026
    gpg: using RSA key alice@example.com
    gpg: Good signature from "Alice Chen <alice@company.com>"

Tag requirements policy:
  #!/bin/bash
  # Script run as pre-receive hook on server
  # Enforce tag requirements
  
  while read oldrev newrev ref; do
    if [[ $ref == refs/tags/* ]]; then
      TAG_NAME=${ref#refs/tags/}
      
      # Must be annotated tag
      if ! git cat-file -t "$newrev" | grep -q "tag"; then
        echo "❌ Tag $TAG_NAME must be annotated tag"
        exit 1
      fi
      
      # Must be signed
      if ! git tag -v "$TAG_NAME" >/dev/null 2>&1; then
        echo "❌ Tag $TAG_NAME must be GPG signed"
        exit 1
      fi
      
      # Must match version pattern
      if ! [[ $TAG_NAME =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo "❌ Tag $TAG_NAME must match format: v1.2.3"
        exit 1
      fi
    fi
  done
  
  exit 0
```

#### Semantic Versioning for Infrastructure

```
Version format: MAJOR.MINOR.PATCH[-prerelease][+buildmetadata]

Meaning for infrastructure:

MAJOR (1.0.0 → 2.0.0):
  Breaking infrastructure changes
  Examples:
    - Major cloud provider upgrade (AWS v3 → v4 APIs)
    - Database schema migration (incompatible)
    - Terraform major version bump
    - API incompatibility
  
  Deployment impact: May require downtime/preparation

MINOR (1.0.0 → 1.1.0):
  New features, backwards compatible
  Examples:
    - New deployment regions
    - New monitoring added
    - New security groups (no removal of old)
    - Terraform new resources
  
  Deployment impact: Optional updates, green-deployable

PATCH (1.0.0 → 1.0.1):
  Bug fixes, security patches
  Examples:
    - Fix incorrect IAM policy
    - Security group rule correction
    - Configuration typo fix
    - Terraform resource correction
  
  Deployment impact: Recommended update (non-breaking)

Prerelease versions:
  1.0.0-alpha.1       # Early testing
  1.0.0-beta.1        # Beta testing
  1.0.0-rc.1          # Release candidate (production-ready, just last checks)

Versioning decision tree:

  Does this introduce breaking change?
    Yes → MAJOR version bump
    No → Next decision

  Does this add new features?
    Yes → MINOR version bump
    No → PATCH version bump

Infrastructure versioning strategy:

  deploy/production:     v*.*.* (released versions only)
  deploy/staging:        v*.*.*-rc* or v*.*.*-beta*
  develop:               v*.*.*-dev or no version
  feature branches:      No version (or -experiment)
```

#### Release Process Automation

```
Automated Release Pipeline:

Trigger: Tag created (git push origin v1.2.3)
  ↓
Step 1: Validate tag
  - Verify format (v1.2.3)
  - Verify signed
  - Verify not pre-release for production
  ↓
Step 2: Extract release metadata
  - Changelog from git log
  - Version from tag
  - Commit history
  ↓
Step 3: Build artifacts
  - Terraform modules (if any)
  - Container images
  - Documentation
  ↓
Step 4: Run tests
  - Infrastructure validation
  - Deployment tests
  - Smoke tests
  ↓
Step 5: Create release
  - GitHub/GitLab release
  - Attach artifacts
  - Post changelog
  ↓
Step 6: Deploy
  - Staging deployment
  - Production deployment
  - Notifications

Automation script (GitHub Actions):

name: Release Management
on:
  push:
    tags:
      - 'v*.*.*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Parse version
        id: version
        run: |
          VERSION=${GITHUB_REF#refs/tags/}
          echo "version=${VERSION}" >> $GITHUB_OUTPUT
      
      - name: Validate tag
        run: |
          # Must match v*.*.* and be signed
          version=${{ steps.version.outputs.version }}
          if ! [[ $version =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
            echo "Invalid version format: $version"
            exit 1
          fi
      
      - name: Generate changelog
        run: |
          git log $(git describe --tags --abbrev=0 HEAD^)..HEAD \
            --oneline > CHANGELOG.md
      
      - name: Create release
        uses: softprops/action-gh-release@v1
        with:
          body_path: CHANGELOG.md
          draft: false
          prerelease: false
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Deploy to staging
        run: |
          # Terraform/deployment commands
          terraform apply -auto-approve
```

---

### Practical Code Examples: Release Management

**Example 1: Automated Release Tag Creation**

```bash
#!/bin/bash
# create-release.sh
# Create release tag with validation and changelog

set -e

VERSION=${1:?Usage: $0 <version>}
SIGNING_KEY=${2:-}

# Validate version format
if ! [[ $VERSION =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "❌ Invalid version format: $VERSION"
    echo "Expected: v1.2.3"
    exit 1
fi

echo "=== Creating Release $VERSION ==="
echo ""

# Get current branch
CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [ "$CURRENT_BRANCH" != "main" ] && [ "$CURRENT_BRANCH" != "master" ]; then
    echo "⚠️ Warning: Not on main branch (current: $CURRENT_BRANCH)"
    read -p "Continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Ensure repository is clean
if [ -n "$(git status --porcelain)" ]; then
    echo "❌ Repository has uncommitted changes"
    exit 1
fi

# Get previous version
PREV_VERSION=$(git describe --tags --abbrev=0 2>/dev/null || echo "HEAD")
echo "Previous version: $PREV_VERSION"

# Generate changelog
echo ""
echo "=== Generating Changelog ==="
CHANGELOG=$(git log "$PREV_VERSION"..HEAD --oneline --no-decorate)

if [ -z "$CHANGELOG" ]; then
    echo "⚠️ No commits since $PREV_VERSION"
fi

echo "Changes:"
echo "$CHANGELOG" | head -10
if [ $(echo "$CHANGELOG" | wc -l) -gt 10 ]; then
    echo "... and $(( $(echo "$CHANGELOG" | wc -l) - 10 )) more"
fi

# Create release notes
RELEASE_NOTES=$(cat << EOF
# Release $VERSION

$(date +"%A, %B %d, %Y")

## Changes

$CHANGELOG

## Installation

\`\`\`bash
git checkout $VERSION
terraform apply -auto-approve
\`\`\`

## Migration Notes

See MIGRATION.md for upgrade instructions from $PREV_VERSION
EOF
)

echo ""
echo "=== Release Information ==="
echo "$RELEASE_NOTES"

echo ""
read -p "Create release? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "❌ Release cancelled"
    exit 1
fi

# Create tag
if [ -n "$SIGNING_KEY" ]; then
    git tag -s -u "$SIGNING_KEY" "$VERSION" -m "$RELEASE_NOTES"
    echo "✅ Signed tag created: $VERSION"
else
    git tag -a "$VERSION" -m "$RELEASE_NOTES"
    echo "✅ Tag created: $VERSION"
fi

# Push tag
read -p "Push to remote? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    git push origin "$VERSION"
    echo "✅ Tag pushed to origin"
fi

echo ""
echo "=== Release Complete ==="
echo "To view release:"
echo "  git show $VERSION"
echo ""
echo "To push all changes:"
echo "  git push origin main --tags"
```

**Example 2: Multi-Environment Deployment with Tags**

```bash
#!/bin/bash
# deploy-by-tag.sh
# Deploy infrastructure from specific tag to different environments

set -e

VERSION=${1:?Usage: $0 <version> [environment]}
ENVIRONMENT=${2:-staging}

VALID_ENVS=("staging" "production")
if [[ ! " ${VALID_ENVS[@]} " =~ " ${ENVIRONMENT} " ]]; then
    echo "❌ Invalid environment: $ENVIRONMENT"
    echo "Valid: ${VALID_ENVS[*]}"
    exit 1
fi

echo "=== Deployment: $VERSION → $ENVIRONMENT ==="
echo ""

# Verify tag exists
git fetch --tags
if ! git rev-parse "$VERSION" >/dev/null 2>&1; then
    echo "❌ Tag not found: $VERSION"
    exit 1
fi

# Show what we're deploying
echo "Changes in $VERSION:"
PREV_TAG=$(git describe --tags --abbrev=0 "$VERSION"^ 2>/dev/null || echo "HEAD")
git log "$PREV_TAG".."$VERSION" --oneline | head -5

echo ""

# Checkout specific version
DEPLOY_DIR="/tmp/deploy-${VERSION}-$$"
git clone --depth 1 --branch "$VERSION" . "$DEPLOY_DIR"
cd "$DEPLOY_DIR"

echo "Checked out: $(pwd)"
echo ""

# Environment-specific configuration
case $ENVIRONMENT in
    staging)
        TF_WORKSPACE="staging"
        APPROVAL_REQUIRED=false
        AUTO_APPROVE="-auto-approve"
        ;;
    production)
        TF_WORKSPACE="production"
        APPROVAL_REQUIRED=true
        AUTO_APPROVE=""
        ;;
esac

echo "Environment: $ENVIRONMENT"
echo "Workspace: $TF_WORKSPACE"
echo ""

# Set workspace
terraform workspace select "$TF_WORKSPACE"

# Show plan
echo "=== Infrastructure Plan ==="
terraform plan -out="/tmp/plan-$$.tfplan"

echo ""

# Approval step
if [ "$APPROVAL_REQUIRED" = true ]; then
    echo "⚠️ Production deployment requires approval"
    echo ""
    echo "Approve? (type 'APPROVE' to continue)"
    read -r approval
    if [ "$approval" != "APPROVE" ]; then
        echo "❌ Deployment cancelled"
        exit 1
    fi
fi

# Apply configuration
echo ""
echo "=== Applying Configuration ==="
terraform apply $AUTO_APPROVE "/tmp/plan-$$.tfplan"

echo ""
echo "✅ Deployment complete: $VERSION → $ENVIRONMENT"

# Cleanup
rm -rf "$DEPLOY_DIR"
rm -f "/tmp/plan-$$.tfplan"

# Post-deployment
echo ""
echo "=== Post-Deployment ==="
echo "Validating deployment..."

# Check deployed version
DEPLOYED=$(terraform output version 2>/dev/null || echo "unknown")
echo "Deployed version: $DEPLOYED"

if [ "$DEPLOYED" = "$VERSION" ]; then
    echo "✅ Version verified"
else
    echo "⚠️ Version mismatch (expected $VERSION, got $DEPLOYED)"
fi
```

---

### ASCII Diagrams: Release Pipeline

**Diagram 1: Complete Release Workflow**

```
Development Phase:
  Development ─► Commit ─► Code Review ─► Merge to main
  (multiple PRs, iterations)

Release Decision:
  main branch stable
    ↓
  Create release plan
  (decide what ships)

Tagging:
  git tag -s v1.2.0 -m "Release: Version 1.2.0"
    ↓
  Tag pushed to remote

Release Automation Triggered:
  
  ┌─────────────────────────────┐
  │ GitHub: Release Workflow    │
  │ (triggered by tag)          │
  ├─────────────────────────────┤
  │ 1. Validate Tag            │ ─► Check format, signature
  │                            │
  │ 2. Generate Release Notes  │ ─► git log changelog
  │                            │
  │ 3. Build Artifacts         │ ─► Terraform modules
  │                            │
  │ 4. Create Release Page     │ ─► GitHub Release
  │                            │
  │ 5. Run Tests               │ ─► terraform validate
  │                            │
  │ 6. Deploy to Staging       │ ─► Auto-deploy
  │                            │
  │ 7. Smoke Tests             │ ─► Verify deployment
  │                            │
  │ 8. Wait for Approval       │ ─► Manual step
  │                            │
  │ 9. Deploy Production       │ ─► Blue/green deploy
  │                            │
  │ 10. Notifications          │ ─► Slack, email
  └─────────────────────────────┘

Post-Deployment:
  Monitor for issues (30 min)
    ↓
  Update release notes with metrics
    ↓
  Mark release complete

Recovery (if needed):
  If critical issue:
    - Create hotfix branch
    - Create v1.2.1 tag
    - Deploy hotfix
    - Close v1.2.0
```

**Diagram 2: Multi-Environment Release Timeline**

```
Release Timeline:

─────────────────────────────────────────────────────────────

v1.2.0 tagged at 14:00
  │
  ├─ Staging environment
  │    14:05: Deploy starts
  │    14:15: Tests pass
  │    14:20: Manual verification
  │    14:30: Ready for production
  │
  ├─ Production environment
  │    14:30: Approval given
  │    14:32: Deploy starts (blue)
  │    14:42: Health checks pass
  │    14:45: Switch traffic (green)
  │    14:46: Zero-downtime achieved
  │    15:00: Monitoring period start
  │    15:30: Mark complete
  │
  └─ Rollback capability active
       Until 16:00 (30 min after):
         - v1.1.3 tagged
         - Instant rollback available

─────────────────────────────────────────────────────────────
```

---

**Document Version:** 3.0  
**Last Updated:** March 18, 2026  
**Target Audience:** Senior DevOps Engineers (5-10+ years experience)  
**Related:** Part 1 & Part 2 Study Guides  
**Prerequisites:** Foundational Git knowledge, infrastructure deployment experience
