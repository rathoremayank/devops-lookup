# Git Source Control: Branching, Merging, Rebasing & Advanced Operations
## Senior DevOps Engineering Study Guide - Part 2

---

## Table of Contents

### Core Workflow Commands (Continued)
1. [diff, show, reset, checkout, revert, stash](#core-workflow-continued)

### Branching & Merging Strategies
2. [Branching Fundamentals](#branching-fundamentals)
3. [Merging Concepts](#merging-concepts)
4. [Rebasing and History Management](#rebasing-and-history-management)

### Distributed Operations
5. [Remote Repository Operations](#remote-repository-operations)
6. [Tags & Release Management](#tags--release-management)

### Practical Application
7. [Hands-on Scenarios](#hands-on-scenarios)
8. [Interview Questions for Senior Engineers](#interview-questions-for-senior-engineers)

---

## Core Workflow Commands (Continued)

### diff, show, reset, checkout, revert, stash

#### git diff: Understanding Changes

```
Purpose: Examine differences between versions
  - Compare working directory to staging area
  - Compare staging area to last commit
  - Compare arbitrary commits/branches
  - Show changes before committing

Basic diff (unstaged changes):
  git diff                    # Working dir vs. staging area
  git diff file.tf            # Specific file only

Staged changes (already added):
  git diff --staged           # Staging area vs. committed
  git diff --cached           # Alias for --staged

Comparing commits/branches:
  git diff main develop       # Branch to branch
  git diff HEAD~2 HEAD        # Two commits back to current
  git diff commit1 commit2    # Specific commits
  git diff v1.0 v1.1          # Tags

Filtering by file:
  git diff main -- terraform/ # Only path
  git diff -- '*.py'          # Glob pattern

Statistics only:
  git diff --stat             # Summary of changes
  git diff --numstat          # Machine-readable stats

Word-level diff:
  git diff --word-diff        # Show word-level changes
  git diff --color-words      # Colored word diff

Checking impact before merge:
  git diff main..feature      # What feature adds to main
  git diff main...feature     # Changes in feature since divergence

DevOps use: Review IaC changes before applying
  #!/bin/bash
  # Review terraform changes before tfapply
  git diff main -- terraform/
  echo "Does this look correct? (yes/no)"
  read response
  if [ "$response" = "yes" ]; then
    terraform apply
  fi
```

#### git show: Examining Specific Commits

```
Purpose: Display complete information about specific commit

Syntax:
  git show <commit>           # Show commit details
  git show <commit>:<file>    # Show file at specific commit

Examples:
  git show HEAD               # Current commit
  git show HEAD~1             # Previous commit
  git show abc123d            # Specific commit hash
  git show main               # Latest on main branch
  git show tag-name           # Tagged commit

Output includes:
  - Commit hash and tree
  - Author and committer
  - Timestamp
  - Full commit message
  - Complete diff (all changes)

Show specific file version:
  git show commit:file.txt    # Content of file at commit
  git show HEAD~2:terraform/main.tf

Formatting:
  git show --stat commit      # Just statistics
  git show --name-only commit # Only filenames
  git show --oneline commit   # Summary format

Pattern matching:
  git show ':/search_text'    # Latest commit matching text
  git show ':/deployment'     # Latest deployment commit

DevOps use: Find when something changed
  # What version of config was deployed?
  git show v1.2.3:config/settings.yaml
  
  # Find most recent deployment change
  git show ':/production deployment'
```

#### git reset: Undoing Changes (Dangerous)

```
Purpose: Move HEAD and modify working directory/staging
  - Dangerous because it rewrites history
  - Only safe on unpushed commits
  - Three modes: soft, mixed (default), hard

Modes explained:
  1. --soft: Move HEAD only, keep changes staged
  2. --mixed (default): Move HEAD, unstage changes
  3. --hard: Move HEAD, discard changes (DANGEROUS)

Undo last commit (keep changes):
  git reset --soft HEAD~1     # Last commit moved to staging
  git commit --amend          # Add more changes to same commit

Undo staged changes:
  git reset                   # Unstage all changes (default --mixed)
  git reset file.tf           # Unstage specific file

Discard all local changes (irreversible):
  git reset --hard HEAD       # Restore to last commit (lose work!)

Reset to specific commit:
  git reset --hard abc123d    # Revert to specific commit
  git reset --hard origin/main # Revert to remote state

Before/after reset:
  Before: A → B → C → D (HEAD)
  
  git reset --soft HEAD~2:
  After:  A → B (HEAD)
          Changes from C,D staged

Recovery if reset too far:
  git reflog                  # Show all HEAD changes
  git reset --hard <old_ref>  # Restore previous state

⚠️ WARNING: --hard reset discards work
  # Check before resetting
  git diff HEAD               # Review changes first
  git stash                   # Save changes before reset
  
DevOps caution: Never use reset on shared branches
  # Safe alternatives:
  git revert HEAD             # Create new commit undoing HEAD
  git log --oneline           # Review history before changing
```

#### git checkout: Switching Context

```
Purpose: Switch branches or restore files

Switching branches:
  git checkout main           # Switch to main branch
  git checkout develop        # Switch to develop
  git checkout feature/auth   # Switch to feature branch

Creating and switching:
  git checkout -b feature/new   # Create and switch to new branch

Restoring files (from staging or HEAD):
  git checkout file.tf        # Restore file from HEAD
  git checkout -- file.tf     # Explicit (discard changes)
  git restore file.tf         # Newer syntax (preferred)

Detached HEAD (checking out commit):
  git checkout abc123d        # Switch to specific commit
  # Result: Detached HEAD state (not on a branch)
  
  Creating branch from detached state:
    git checkout -b bugfix/issue123  # Create branch from current commit

Checking out from specific commit:
  git checkout abc123d -- file.tf  # Get file version from commit

Remote branch checkout:
  git checkout origin/develop  # Creates local tracking branch
  # Or: git switch -c develop origin/develop

Modern alternatives (Git 2.23+):
  git switch main             # Instead of checkout
  git switch -c feature/new   # Create branch
  git restore file.tf         # Restore file (clearer intent)

DevOps use: Preparing for deployments
  # Deploy from specific tag
  git checkout v1.2.3
  terraform apply
  
  # But better: Use git worktree for this
```

#### git revert: Safe Undo (Creates New Commit)

```
Purpose: Create new commit undoing previous changes (safe on shared branches)

Reverting last commit:
  git revert HEAD             # Creates commit undoing HEAD
  git revert HEAD~1           # Revert specific commit in history

Reverting range:
  git revert abc123d..def456e # Revert multiple commits

Revert without editing message:
  git revert --no-edit HEAD   # Auto-generate message

Handling conflicts during revert:
  git revert <commit>         # Conflict occurs
  # Resolve conflicts manually
  git add .
  git revert --continue       # Or: git commit

Abort revert:
  git revert --abort          # Cancel revert operation

Revert vs. Reset comparison:
```

| Aspect | revert | reset |
|--------|--------|-------|
| Creates new commit | Yes | No |
| Safe on shared branches | Yes | No |
| Modifies history | No (adds) | Yes (rewrites) |
| Use case | Public/shared | Local/unpushed |
| Team impact | Can merge normally | Forces others to rebase |

```
DevOps use case: Emergency rollback on deployed code
  # Bad commit deployed, need to revert safely
  git revert abc123d          # Create undo commit
  git push origin main        # Deploy undo
  # Result: Safe, auditable, team-friendly
```

#### git stash: Temporary Storage

```
Purpose: Save changes temporarily without committing

Stashing changes:
  git stash                   # Stash all changes
  git stash save "message"    # Named stash
  git stash push -m "WIP"     # Explicit push

Specific files:
  git stash push file.tf      # Stash only one file
  git stash -u                # Include untracked files

Listing stashes:
  git stash list              # Show all stashes
  
  Output:
    stash@{0}: WIP on main: abc123d message
    stash@{1}: feature refactor on develop: def456e message

Applying stash:
  git stash pop               # Apply and remove last stash
  git stash apply             # Apply but keep stash
  git stash apply stash@{1}   # Apply specific stash

Clearing stashes:
  git stash drop              # Delete last stash
  git stash drop stash@{1}    # Delete specific stash
  git stash clear             # Delete all stashes

Partial stash operations:
  git stash pop --index       # Restore staging status too

Branching from stash:
  git stash branch bugfix     # Create branch with stash applied
  # Useful if stash conflicts with current branch

DevOps workflow:
  #!/bin/bash
  # Emergency hotfix while work in progress
  git stash                       # Save current work
  git checkout -b hotfix/urgent
  # Make urgent fix
  git push origin hotfix/urgent
  # Create PR and merge
  
  # Return to previous work
  git checkout main
  git stash pop                   # Restore work
```

---

## Branching Fundamentals

### Textual Deep Dive: Branch Models and Strategies

#### Creating and Managing Branches

```
Creating branches:
  git branch feature/auth      # Create branch (don't switch)
  git branch -b feature/auth   # Create and switch
  git switch -c feature/auth   # Modern syntax

Listing branches:
  git branch                   # Local branches
  git branch -a                # All (including remote tracking)
  git branch -r                # Remote branches only
  git branch --merged          # Merged branches (safe to delete)
  git branch --no-merged       # Unmerged branches

Branch information:
  git branch -v                # Branches with commit hashes
  git branch -vv               # Branches with upstream info
  
  Output:
    * main                   abc123d Fix: update config
      develop                def456e Feature: add auth
      feature/logging        ghi789a WIP: logging implementation
      (the * shows current branch)

Upstream tracking:
  git branch --set-upstream-to=origin/main  # Set upstream for current
  git branch -u origin/main                 # Shorthand
  git branch --track develop origin/develop # Create tracking branch

Deleting branches:
  git branch -d feature/old    # Delete (safe, only if merged)
  git branch -D feature/wip    # Force delete (lose work if unmerged)
  git branch -dr origin/old    # Delete remote tracking branch

Renaming branches:
  git branch -m old-name new-name          # Rename
  git branch -m new-name                   # Rename current

Branch naming conventions:

Pattern: type/description
  feature/authentication          # New feature
  bugfix/login-crash              # Bug fix
  hotfix/security-patch           # Emergency fix
  docs/deployment-guide           # Documentation
  refactor/api-cleanup            # Refactoring
  test/performance-benchmark      # Testing
  ci/github-actions-setup         # CI/CD

Benefits:
  - Namespace branches by type
  - Easier filtering (git branch | grep hotfix)
  - Clear purpose from name
  - Aligns with conventional commits
```

#### Branching Strategies for DevOps

**Trunk-Based Development (Recommended for DevOps/Infrastructure)**

```
Philosophy: Develop on single primary branch (main/trunk)
  - Short-lived feature branches (< 1 day)
  - Continuous integration on main
  - Feature flags for incomplete features
  - Frequent small deployments (multiple/day)

Branch structure:
  main (primary development)
  ├── Short-lived feature branches (hours)
  └── Merged back daily

Benefits:
  ✓ Fast feedback (no long Integration time)
  ✓ Fewer merge conflicts
  ✓ Catches integration issues immediately
  ✓ Enables CD (always deployable main)
  ✓ Simpler mental model
  ✓ Less branch management

Implementation:
  1. Create short feature branch
  2. Implement feature with feature flags
  3. PR review (usually quick)
  4. Merge to main with tests passing
  5. Deploy from main immediately
  6. Monitor and flag off if issues

DevOps use:
  # Infrastructure change
  git checkout -b feature/add-prometheus
  # Implement monitoring infrastructure
  # Feature flag enables new monitoring in main
  git push origin feature/add-prometheus
  # PR, review, merge to main
  # Deploy from main
```

**GitFlow (For Scheduled Releases)**

```
Philosophy: Multiple long-lived branches with releases
  - main: Production releases only
  - develop: Integration branch
  - feature branches
  - release branches
  - hotfix branches

Branch structure:
  main (production, release tags)
  ├── hotfix branches
  └── release branches
  
  develop (integration)
  └── feature branches

Workflow:
  1. Feature branches off develop
  2. PR review, merge to develop
  3. Tag release, create release branch
  4. Final testing/fixes on release branch
  5. Merge release to main, tag version
  6. Merge back to develop
  7. Delete release branch

Advantages:
  ✓ Clear separation of versions
  ✓ Scheduled release management
  ✓ Hotfix process for production

Disadvantages:
  ✗ Many long-lived branches = integration issues
  ✗ Complexity for teams < 20
  ✗ Prevents continuous deployment
  ✗ Higher merge conflict frequency

Best for:
  - Products with scheduled releases (quarterly, monthly)
  - Multiple parallel versions in production
  - Clear versioning requirements
```

**GitHub Flow (Hybrid Approach)**

```
Philosophy: Single primary branch (main) + PRs for review

Branch structure:
  main (always deployable)
  └── Feature/PR branches

Workflow:
  1. Create branch for feature/fix
  2. Make commits
  3. Push and create PR
  4. Code review and discussion
  5. Test in branch (CI checks)
  6. Merge to main when approved
  7. Delete branch
  8. Deploy from main

Benefits:
  ✓ Simple mental model
  ✓ Code review before merge
  ✓ Enables CD
  ✓ Fewer conflicts than GitFlow
  ✓ PR-centered workflow
  ✓ Good for open source

Recommended for:
  - DevOps/Infrastructure repos
  - Cloud-native development
  - Teams of all sizes
  - Continuous deployment

Implementation in DevOps:
  # PR workflow
  git checkout -b feature/terraform-modules
  # Develop feature
  git push origin feature/terraform-modules
  # Create PR on GitHub
  # Tests run automatically
  # Review by peer
  # Merge to main when approved
```

#### Upstream Tracking and Branch Protection

```
Upstream (default merge target):
  Purpose: Specify which remote branch to merge from with git pull

Setting upstream:
  git push -u origin main     # Push with upstream set
  git branch -u origin/main   # Set upstream after push
  git config branch.main.remote origin
  git config branch.main.merge refs/heads/main

Checking upstream:
  git branch -vv              # Show upstream for all branches
  git status                  # Shows "ahead/behind" info
  git rev-list HEAD@{u}..     # Commits behind upstream
  git rev-list ..HEAD@{u}     # Commits ahead of upstream

Branch protection (GitHub/GitLab):

Essential protections:
  1. Require PR review (≥2 for main)
  2. Require status checks pass (CI/CD)
  3. Dismiss stale reviews on push
  4. Require up-to-date branches
  5. Restrict who can push
  6. Require signed commits (optional, recommended)
  7. Include administrators in rules

Protection strategy for DevOps:
  main:
    - Require 2 reviewers
    - Require all checks pass
    - Cannot force push
    - Must be up-to-date
    - Require signed commits
    - Dismiss stale reviews
  
  develop:
    - Require 1 reviewer
    - Require checks pass
    - Allow force push (for rebase)
  
  feature/*:
    - No protection (developers can force)
    - Require checks pass (CI)
```

---

## Merging Concepts

### Textual Deep Dive: Algorithms and Conflict Resolution

#### Merge Algorithms

**Fast-Forward Merge**

```
Scenario: Feature branch is ahead of main, no divergence

History before merge:
  main → A → B → C
            ↗ feature → D

  (feature is direct descendant of main's commit C)

Merge command:
  git checkout main
  git merge feature

Result (fast-forward):
  main → A → B → C → D
                      ↑ feature, main (same commit)

Git's action:
  - No new commit created
  - Just move main pointer to D
  - Preserves linear history
  - Loses information that feature existed

When to avoid:
  - Want to preserve branch information
  - Want explicit merge commit for release
  - Deploy tracking (which feature shipped together)

Enforce non-fast-forward:
  git merge --no-ff feature    # Create explicit merge commit
  
  Result:
    main → A → B → C → D (merge commit from feature)
               └─────────┘
```

**Three-Way Merge (Actual Merging)**

```
Scenario: Both branches have commits since divergence

History before merge:
  main → A → B → C (new commits)
           ↗ feature → D → E (feature work)

Three-way merge compares:
  1. Current (main's C)
  2. Target (feature's E)
  3. Common ancestor (B)

Git algorithm:
  1. Find common ancestor (B)
  2. Compare B→C (main changes)
  3. Compare B→E (feature changes)
  4. Auto-merge where no conflict:
     - If changed in main only: take main's version
     - If changed in feature only: take feature's version
     - If changed in both same way: accept
  5. If changed differently in both: conflict!

Result merge commit:
  main → A → B → C
           ↗-→ D → E
                ↖__M (merge commit, 2 parents: C + E)
           
  M has both parents:
    - Default commit message: "Merge branch 'feature' into main"
    - Contains all changes from both branches
```

**Merge Conflict**

```
Occurs when: Both branches modified same lines differently

Example conflict:
  # main version
  server_count = 3
  
  # feature version
  server_count = 5
  
  Git conflict marker:
    <<<<<<< HEAD (main's version)
    server_count = 3
    =======
    server_count = 5
    >>>>>>> feature (feature's version)

Resolving conflict:
  1. Edit file, choose version (or combine)
  2. Remove conflict markers
  3. git add <file>
  4. git commit

Manual resolution:
  <<<<<<< HEAD
  server_count = 3
  =======
  server_count = 5
  >>>>>>> feature
  
  Choose one or combine:
  server_count = 5  # Or: 3, or: max(3,5), or logic
  
  Then: git add . && git commit

Conflict resolution tools:
  # Let merge tool handle visually
  git mergetool                 # Opens configured tool
  
  # Use ours (accept current branch)
  git checkout --ours file.tf
  
  # Use theirs (accept incoming branch)
  git checkout --theirs file.tf

Aborting merge:
  git merge --abort            # Cancel merge, return to pre-merge state

Binary file conflicts:
  # Can't merge binary files (images, PDFs)
  # Must choose one or other, or resolve manually
  git checkout --ours image.png
  git add image.png
  git commit
```

#### Merge Strategies

```
-s strategy: Determines how Git handles 3-way merge

Default strategy: recursive
  - Suitable for most merges
  - Intelligently handles complex histories
  - Can be slow on large repos

Strategy options:

1. recursive (default)
  git merge feature                # Implicit recursive
  Behavior: 3-way merge with intelligent diff3
  Use: Most common, default

2. resolve
  git merge -s resolve feature
  Behavior: 3-way merge, simple algorithm
  Use: When recursive is slow or wrong

3. ours
  git merge -s ours feature
  Behavior: Keep current branch, ignore feature
  Result: Empty merge (no changes from feature)
  Use: Deliberately ignoring branch

4. subtree
  git merge -s subtree feature
  Behavior: Rename one tree to prevent false conflicts
  Use: Merging different subtrees

5. octopus
  git merge branch1 branch2 branch3
  Behavior: Merge multiple branches at once
  Use: Rare, non-conflicting merges only

Strategy options (-X):
  git merge -X theirs feature      # Prefer their version on conflicts
  git merge -X ours feature        # Prefer our version on conflicts

Infrastructure conflict resolution pattern:
  # Two teams modified terraform
  # Default merge: conflicts likely
  # Resolution: Coordinate changes
  
  git merge --no-commit develop   # Merge without committing
  # Manually verify terraform is correct
  # Test terraform apply -plan
  terraform plan
  git commit                      # Commit if plan looks safe
```

---

## Rebasing and History Management

### Textual Deep Dive: Rebase vs. Merge, Interactive Rebase

#### git rebase: Replaying Commits

```
Purpose: Reapply commits on top of different base
  - Linear history (no merge commits)
  - Each commit re-created with new hash
  - Rewrites history (dangerous on shared branches)

Simple rebase:
  Before:
    main → A → B → C
             ↗ feature → D → E
  
  git rebase main feature:
  
  After:
    main → A → B → C → D' → E'
           (D' and E' are new commits with new hashes)

Why rebase (advantages):
  ✓ Linear history (easier to read)
  ✓ Clean log (no merge commits)
  ✓ Easier bisection (git bisect)
  ✓ Cleaner blame (git blame)

Why not rebase (disadvantages):
  ✗ Rewrites history (breaks shared references)
  ✗ Difficult to track branch integration
  ✗ Can confuse history visualization

Rebase options:
  git rebase -i HEAD~3        # Interactive rebase last 3 commits
  git rebase --continue       # After resolving conflicts
  git rebase --abort          # Cancel rebase
```

#### Interactive Rebase for History Cleanup

```
Purpose: Rewrite history before pushing
  - Squash commits
  - Reorder commits
  - Amend commit messages
  - Split commits
  - Drop commits

Interactive rebase:
  git rebase -i HEAD~3        # Rebase last 3 commits interactively
  git rebase -i main          # Rebase current up to main
  git rebase -i commit-hash   # Rebase up to specific commit

Editor opens with:
  pick abc123d Add auth middleware
  pick def456e Add logging
  pick ghi789a Fix typo in logging
  
  # Commands:
  # p = pick (use commit)
  # r = reword (use, but edit message)
  # e = edit (use, but stop for editing)
  # s = squash (combine with previous)
  # f = fixup (combine, discard message)
  # d = drop (remove)
  # x = exec (run command)
  # b = break (pause)
  # l = label (mark commit)

Example: Squash commits
  Original:
    pick abc123d Add auth middleware
    pick def456e Add logging
    pick ghi789a Fix typo in logging
  
  Change to:
    pick abc123d Add auth middleware
    squash def456e Add logging
    squash ghi789a Fix typo in logging
  
  Result: Single commit with combined message

Example: Rewrite history with interactive rebase
  #!/bin/bash
  # Cleanup work before pushing
  git rebase -i main
  
  # In editor:
  # pick abc123d Feature: add authentication
  # fixup def456e WIP: forgot to add test
  # fixup ghi789a typo fix
  # reword jkl012a Add documentation
  
  # Result:
  # abc123d Feature: add authentication (with test & fixes)
  # jkl012a Add documentation (message reworded)

Squashing commits for PR:
  # Before pushing to shared branch
  git rebase -i origin/main
  
  # Mark all commits except first as "squash"
  # Combine into single clean commit
  # Forces users see clean history

Abort interactive rebase:
  git rebase --abort           # Cancel and return to pre-rebase state

Safety with force push:
  git rebase -i origin/main
  # After rebase
  git push --force-with-lease  # Safe force push
  # (fails if someone else pushed to remote)
```

#### Best Practices for Rebasing

```
GOLDEN RULE: Never rebase publicly-pushed commits

Why:
  - Breaks other developers' work
  - Creates duplicate commits
  - Causes conflicts for others
  - Ruins collaboration

Safe to rebase:
  1. Local commits not yet pushed
  2. Feature branch before PR
  3. With --force-with-lease after coordination

Workflow pattern:
  1. Create feature branch
  2. Work locally, commit
  3. Before pushing, rebase interactively
    git rebase -i main
    # Squash, reword, clean up
  4. Push to remote
  5. Never force push after others pull

Team agreement:
  # Document in CONTRIBUTING.md
  "Rebase your feature branch before pushing PR,
   but never rebase main or develop branches."

Rebase safety:
  git config branch.autosetuprebase local  # Rebase auto-pulled
  git config pulls.rebase true             # git pull uses rebase
  git push --force-with-lease              # Safer than --force

Mixed workflow (rebase + merge):
  ✓ Rebase feature branches locally (before push)
  ✓ Merge feature into main (preserve branch info)
  
  Command:
    git pull --rebase                      # Local cleanup
    git push origin feature/auth
    # Then merge via PR
```

---

## Remote Repository Operations

### Textual Deep Dive: Distributed Workflows and Fork vs. Clone

#### Adding and Managing Remotes

```
Remote: Alias for remote repository URL

Remotes configuration:
  git remote                      # List remotes
  git remote -v                   # With URLs
  git remote show origin          # Details
  
  Output:
    origin  https://github.com/org/repo.git (fetch)
    origin  https://github.com/org/repo.git (push)
    upstream https://github.com/source/repo.git (fetch)

Adding remote:
  git remote add origin https://github.com/org/repo.git
  git remote add upstream https://github.com/upstream/repo.git
  git remote add mirror https://mirror.example.com/repo.git

Common remote names:
  origin: Your repository (or fork)
  upstream: Original repository (if forked)
  mirror: Backup/readonly copy

Changing remote URL:
  git remote set-url origin new-url
  git remote set-url origin ssh://git@github.com/org/repo.git

Removing remote:
  git remote remove origin

Tracking branches:
  git branch -r                   # List remote-tracking branches
  output: origin/main, origin/develop

Remote tracking behavior:
  git fetch origin                # Updates origin/* branches
  origin/main → points to remote main
  (these are local copies of remote state)
```

#### Fetch vs. Pull Revisited

```
Fetch (Safe for exploration):
  git fetch origin                # Get latest from remote
  - Downloads new commits
  - Updates remote-tracking branches
  - Doesn't modify local branches
  - Doesn't modify working directory
  
Before merge check:
  git fetch origin
  git log main..origin/main       # What we'd get
  git diff main...origin/main     # Differences
  git merge origin/main           # If happy, merge

Pull (Convenience):
  git pull                        # Fetch + merge
  git pull --rebase               # Fetch + rebase (cleaner)
  
Workflow:
  # Fetch first, review, then merge
  git fetch origin
  git log main..origin/main
  git merge origin/main

DevOps workflow (CI/CD):
  #!/bin/bash
  # Deploy from main branch
  git fetch origin
  if ! git diff --quiet main origin/main; then
    echo "Main has changes, rebuilding..."
    git merge origin/main
    ./deploy.sh
  fi
```

#### Fork vs. Clone

**Clone (Copy repo locally)**

```
Purpose: Create local development environment

What happens:
  git clone https://github.com/org/repo.git
  1. Creates new directory
  2. Gets all commits/objects
  3. Sets up origin as remote
  4. Creates local tracking branches
  5. Checks out default branch

Result:
  Local repo with origin pointing to original
  
When to use:
  - You have write access to repository
  - Contributing to private projects
  - Internal company infrastructure
  - Backup/mirror scenarios

Limitations:
  - Only access you have is push/pull
  - Can't modify remotes easily
  - Can't host your own version
```

**Fork (Copy on server)**

```
Purpose: Create your own server copy for contributions

What happens (on GitHub):
  1. GitHub duplicates repository on their server
  2. Your fork is independent repository
  3. Original becomes "upstream"
  4. You clone fork to work locally

Workflow:
  1. Fork on GitHub (UI button)
  2. Clone fork: git clone your-fork-url
  3. Add upstream: git remote add upstream original-url
  4. Work on feature branch
  5. Push to your fork
  6. Create PR from fork to upstream

When to use:
  - Contributing to open source
  - No write access to original repository
  - Want independent copy with history
  - Experimental modifications

Fork setup:
  git clone https://github.com/yourname/repo.git
  cd repo
  git remote add upstream https://github.com/original/repo.git
  git fetch upstream
  git checkout -b feature upstream/main

Keeping fork updated:
  git fetch upstream
  git rebase upstream/main            # Update current branch
  git push origin main --force-with-lease

Multiple contributor coordination:
  # Two developers, one fork
  # Add each other's fork
  git remote add colleague https://github.com/colleague/repo.git
  git fetch colleague
  git merge colleague/feature
  # Collaborate before pushing back to main fork
```

#### Mirror Repositories

```
Purpose: Create backup/secondary copy for redundancy

Mirror clone:
  git clone --mirror https://github.com/org/repo.git repo.mirror.git
  # Result: Bare repository with all refs

Mirror as backup:
  #!/bin/bash
  # Regular mirror backup
  cd /backups/mirrors
  if [ -d repo.mirror.git ]; then
    cd repo.mirror.git
    git fetch --all --prune        # Update all refs
  else
    git clone --mirror original-url repo.mirror.git
  fi
  
  # Schedule: cron job daily
  0 2 * * * /backups/mirror_backup.sh

Cloning from mirror:
  git clone /mirrors/repo.mirror.git repo-work
  git remote set-url origin https://github.com/org/repo.git

Multi-region mirrors:
  Primary: https://github.com/org/repo.git
  Mirror1: https://mirror1.example.com/repo.git (Asia)
  Mirror2: https://mirror2.example.com/repo.git (Europe)
  
  Clone from nearest geographically:
    git clone --reference mirror1 https://mirror1.example.com/repo.git

DevOps infrastructure repo mirror pattern:
  # Disaster recovery
  git clone --mirror https://github.com/company/infrastructure.git \
    /backups/infrastructure.git
  
  # High availability
  # Mirror synced regularly
  # If primary down, clone from mirror
  # CI/CD can use nearest mirror for speed
```

---

## Tags & Release Management

### Textual Deep Dive: Semantic Versioning and Release Process

#### Tag Types and Creation

```
Tags: Permanent reference to specific commit (usually releases)

Two types:

Lightweight tag:
  git tag v1.0.0                  # Simple ref to commit
  # Just a reference, not a full object
  git push origin v1.0.0
  
Annotated tag:
  git tag -a v1.0.0 -m "Release 1.0.0"  # Full object with metadata
  # Contains: tagger, date, message, signature
  git push origin v1.0.0
  
When to use:
  Lightweight: Temporary, internal
  Annotated: Public, releases (create with metadata)

Tag best practices for DevOps:
  # Always use annotated tags for releases
  git tag -a v1.0.0 -m "Release: Production deployment"
  
  # Or with GPG signing
  git tag -s v1.0.0 -m "Release: Signed for audit"

Listing tags:
  git tag                         # All tags
  git tag -l "v1.*"               # Filter pattern
  git tag -l -n3                  # With annotations (3 lines)
  git describe                    # Nearest tag + commits

Tag details:
  git show v1.0.0                 # Show tagged commit
  git show-ref --tags             # All tags with hashes

Deleting tags:
  git tag -d v1.0.0               # Local delete
  git push origin --delete v1.0.0 # Remote delete
  git push origin :v1.0.0         # Old syntax delete
```

#### Semantic Versioning

```
Format: MAJOR.MINOR.PATCH[-prerelease][+build]

Example: 1.2.3-beta+20260318

Component meanings:

MAJOR version (X.0.0):
  - Increment for breaking changes
  - Incompatible API changes
  - Infrastructure incompatibility
  - Examples: 3.0.0, 4.0.0

MINOR version (1.X.0):
  - Increment for new compatible features
  - Backwards compatible functionality
  - Infrastructure additions
  - Examples: 1.1.0, 1.5.0

PATCH version (1.0.X):
  - Increment for bug fixes
  - Backwards compatible
  - Examples: 1.0.1, 1.0.5

Prerelease (-alpha, -beta, -rc):
  1.0.0-alpha      # Early development
  1.0.0-beta.2     # Beta release 2
  1.0.0-rc1        # Release candidate
  
  Ordering: 1.0.0-alpha < 1.0.0-beta < 1.0.0-rc1 < 1.0.0

Build metadata (+build_metadata):
  1.0.0+20260318               # Build date
  1.0.0+ci.abc123d             # CI build info
  1.0.0+build.1.2.3            # Build number
  
  Build metadata does NOT affect version precedence

DevOps release tagging:
  # Feature release
  git tag -a v2.3.0 -m "Release: New multi-region support"
  
  # Patch release
  git tag -a v2.3.1 -m "Release: Fix DNS resolution"
  
  # Pre-release
  git tag -a v3.0.0-beta.1 -m "Release: Beta test new architecture"
```

#### Release Process

```
Recommended release workflow:

1. Plan Release
  - Changelog: git log v1.0.0..main --oneline
  - Version bump: MAJOR.MINOR.PATCH?
  - Communication: Notify stakeholders

2. Prepare Release
  - Create release branch: git checkout -b release/v2.0.0
  - Update version (setup.py, package.json, etc.)
  - Update CHANGELOG.md
  - Commit: git commit -m "chore: bump version to 2.0.0"

3. Tag Release
  - Annotated tag: git tag -a v2.0.0 -m "Release: 2.0 "
  - Signed tag (optional): git tag -s v2.0.0 -m "Release: 2.0"
  - Verify: git show v2.0.0

4. Push Release
  - Push branch: git push origin release/v2.0.0
  - Push tag: git push origin v2.0.0
  - Verify: git tag -l v2.0.0 on remote

5. Build/Deploy
  - CI/CD triggered by tag push
  - Build artifacts
  - Deploy to production
  - Monitor

6. Merge Back
  - Ensure branch in sync: git pull
  - Merge to main/develop: git merge release/v2.0.0
  - Push: git push origin main develop

7. Document
  - Create GitHub/GitLab release from tag
  - Attach artifacts
  - Document changes

Release automation script:
  #!/bin/bash
  VERSION=$1
  set -e
  
  # Validate version format
  [[ "$VERSION" =~ ^v[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
    (echo "Invalid version: $VERSION"; exit 1)
  
  # Ensure main
  git checkout main
  git pull origin main
  
  # Check version doesn't exist
  git rev-parse "$VERSION" >/dev/null 2>&1 && \
    (echo "Version $VERSION already exists"; exit 1)
  
  # Update version in files
  sed -i "s/VERSION=.*/VERSION=$VERSION/" setup.py
  
  # Commit and tag
  git add setup.py
  git commit -m "chore: bump version to $VERSION"
  git tag -a "$VERSION" -m "Release: $VERSION"
  
  # Push
  git push origin main
  git push origin "$VERSION"
  
  echo "✅ Released $VERSION"
```

---

## Hands-on Scenarios

### Practical DevOps Situations

**Scenario 1: Emergency Hotfix in Production**

```
Situation: Critical bug discovered in production (main deployed)
           Customer-facing feature broken
           Need fix deployed within 30 minutes

Steps:

1. Assess situation
  git log --oneline main | head -5          # Recent commits
  git diff main develop                     # What's in develop
  git status                                # Current state

2. Create hotfix branch
  git checkout -b hotfix/critical-bug main  # Branch from production
  
3. Locate and fix issue
  git log -p --grep="login" -- src/auth.py # Search related commits
  # Edit file, test locally
  
4. Commit fix
  git add -A
  git commit -m "fix: critical login timeout issue
  
  - Increased session timeout from 15m to 30m
  - Fixes customer logout after 15 minutes
  - Tested in staging environment
  
  fixes #9999"

5. Test in CI/CD
  git push origin hotfix/critical-bug
  # Wait for tests to pass
  
6. Deploy immediately
  git push origin hotfix/critical-bug:main  # Push to main
  # Trigger deployment from main tag
  # Or: Create PR and fast-merge

7. Merge back to develop (don't forget!)
  git checkout develop
  git merge --no-ff hotfix/critical-bug
  git push origin develop

8. Clean up
  git branch -d hotfix/critical-bug
  git push origin --delete hotfix/critical-bug

9. Post-mortem
  git log hotfix/critical-bug --oneline    # Document what changed
  # Discuss how to prevent in future
```

**Scenario 2: Large Infrastructure Refactoring (Monorepo)**

```
Situation: Reorganize terraform modules across directories
          16MB repository needed to be restructured
          Multiple teams depending on structure

Plan:
  Current: infrastructure/
           ├── prod/
           ├── staging/
           └── modules/
  
  New:     infrastructure/
           ├── terraform/
           │   ├── prod/
           │   ├── staging/
           │   └── modules/
           ├── kubernetes/
           └── scripts/

Execution:

1. Create feature branch
  git checkout -b refactor/reorganize-infrastructure

2. Reorganize directory structure
  # Use git mv to preserve history
  mkdir terraform
  git mv prod terraform/
  git mv staging terraform/
  git mv modules terraform/
  
3. Update all references
  # Find all imports/references
  git grep "modules/" | grep -v ".git"
  # Update paths in files
  sed -i 's|modules/|terraform/modules/|g' *.tf

4. Verify git history preserved
  git log --follow terraform/prod/main.tf
  # Should show history from old prod/main.tf

5. Test infrastructure
  terraform validate terraform/
  # Ensure all modules still load

6. Commit refactoring
  git add -A
  git commit -m "refactor: reorganize infrastructure directory structure
  
  - Move terraform code to dedicated terraform/ directory
  - Prepare for kubernetes and other IaC alongside
  - Preserve git history for all moved files
  - All paths updated in references
  
  Verification:
    - terraform validate passes
    - All imports updated
    - History preserved via git log --follow"

7. Notify team (before pushing)
  git merge-base HEAD main              # Check distance from main
  git push -u origin refactor/reorganize-infrastructure
  # Create PR with explanation
  # Discuss with team

8. Code review checklist
  - History preserved?
  - References updated?
  - Test infrastructure passes?
  - Documentation updated?

9. Merge strategy
  # Don't squash (loses individual commits)
  # Create merge commit (preserves organization info)
  git checkout main
  git pull origin main
  git merge --no-ff --edit refactor/reorganize-infrastructure
  
  # Merge message documents change intent

10. Cleanup on all machines
  # Communicate to team
  # Each developer: git pull && rm -rf old paths
```

**Scenario 3: Resolving Complex Merge Conflict**

```
Situation: Two teams modified terraform for same resource
          Auto-merge failed, manual resolution required

Scenario:
  Team A (main):
    resource "aws_instance" "app" {
      count = 3
      instance_type = "t3.micro"
    }
  
  Team B (feature/scaling):
    resource "aws_instance" "app" {
      count = 5
      instance_type = "t3.small"
      tags = {
        Environment = "prod"
      }
    }

Resolution:

1. Attempt merge
  git merge feature/scaling
  # Auto-merge failed
  
2. Check status
  git status
  # Shows: UU (both modified)
  // Unmerged paths:
  //   both modified: terraform/ec2.tf

3. Review conflict
  git diff terraform/ec2.tf
  # Shows conflict markers
  
  <<<<<<< HEAD (main)
  count = 3
  instance_type = "t3.micro"
  =======
  count = 5
  instance_type = "t3.small"
  tags = {
    Environment = "prod"
  }
  >>>>>>> feature/scaling

4. Understand intent
  git log --grep="scaling" origin/feature/scaling --oneline
  # Understand feature's scale goal
  
  git log --grep="micro" main --oneline
  # Understand current production setup

5. Resolve intelligently
  # Don't arbitrarily pick one side
  # Combine intent
  
  resource "aws_instance" "app" {
    count = 5                           # Feature's scale
    instance_type = "t3.small"          # Feature upgrade
    tags = {
      Environment = "prod"              # Feature's tag
    }
    # Note: Changed from 3 to 5 instances
    # Verify in code review
  }

6. Add and commit
  git add terraform/ec2.tf
  git commit -m "merge: resolve scaling conflict

  - Accept feature/scaling count (5 instances)
  - Use t3.small instance type from feature
  - Add environment tags
  - Verified with Team A before merging"

7. Verify resolution
  terraform plan                        # Ensure still valid
  terraform validate

8. Push resolved merge
  git push origin main

9. Communication
  Notify Team A:
  "Merged feature/scaling. Changes:
   - Instance count: 3 → 5
   - Instance type: t3.micro → t3.small
   - Added environment tags
   Please review terraform plan."
```

---

## Interview Questions for Senior Engineers

### Technical Deep Dives

**Q1: Explain Git's object model and why content-addressable storage matters for DevOps**

Model Answer:
```
Git's object model consists of 4 types:

1. Blob: File content
   - Identified by SHA hash of contents
   - Immutable (changing content changes hash)
   - Enables content deduplication

2. Tree: Directory snapshot
   - References blobs and nested trees
   - Represents file structure at point in time
   - Also identified by content hash

3. Commit: Historical record
   - References tree (snapshot)
   - References parent commit(s)
   - Contains author, timestamp, message
   - Identified by hash of all metadata

4. Tag: Named reference
   - Lightweight: just a branch pointer
   - Annotated: full object with metadata

Content-Addressable Storage Implications for DevOps:

1. Integrity Verification
   - Any bit corruption produces different hash
   - Automatically detects data corruption
   - Critical for auditability and compliance

2. Deduplication
   - Identical content stored once (by hash)
   - Reduces storage ~40-60% in real systems
   - Infrastructure repos benefit (repeated configs)

3. Reproducibility
   - Commit hash encodes entire state
   - Rebuild from specific commit = identical result
   - Essential for IaC and infrastructure versioning

4. Immutability & Audit Trail
   - Can't secretly modify commits (hash changes)
   - Complete history preserved
   - Perfect for compliance requirements (SOC2, HIPAA)

Example DevOps Impact:
  You deploy from commit abc123d
  - Hash represents exact infrastructure code
  - If deployed again from abc123d: identical result
  - Enables reproducible disaster recovery
  - Audit trail: Who deployed what code when
```

**Q2: Compare rebase vs. merge workflows and when to use each in large teams**

Model Answer:
```
Rebase:
  Linear history, commits replayed on new base
  Advantages:
    ✓ Clean linear history
    ✓ Easier bisection (git bisect)
    ✓ Simpler blame (git blame shows actual change source)
    ✓ Smaller diff files
  
  Disadvantages:
    ✗ Rewrites history (breaks shared refs)
    ✗ Loses integration context
    ✗ Dangerous on shared branches
    ✗ Confuses developers unfamiliar with rebase

Merge:
  Creates merge commit combining two branches
  Advantages:
    ✓ Preserves branch history
    ✓ Non-destructive (no history rewrite)
    ✓ Safe on shared branches
    ✓ Clear integration points
    ✓ Can preserve feature context
  
  Disadvantages:
    ✗ Non-linear history
    ✗ More merge commits (clutter)
    ✗ Harder bisection
    ✗ Larger repository with many branches

Recommendation for Large Teams (20+ engineers):

Strategy: Hybrid Approach
  1. Rebase: Local feature branches (before push)
     - Developers clean up history locally
     - Catch integration issues early
     - Linear local development
  
  2. Merge: Into shared branches (main, develop)
     - Use --no-ff to create explicit merge commits
     - Preserves branch information
     - Non-destructive for shared history
     - Team-friendly (no force pushes)

Implementation:
  # Configure default
  git config --global pull.rebase true
  
  # Workflow
  git checkout -b feature/auth
  # Work locally
  git rebase -i main              # Clean history
  git push origin feature/auth
  # Create PR
  # Review and merge to main with --no-ff
  
  # Result: Linear feature history, clean integration

Enforcement via branch protection:
  main branch:
    - No force push (protect merge commits)
    - Require 2+ reviewers
    - Require tests pass
    - Dismiss stale reviews (encourage rebase)
  
  feature branches:
    - Allow force push (developers clean up)
    - Self-review sufficient

Communication:
  "Rebase feature branches locally to keep history clean.
   Always merge (don't rebase) into main/develop.
   Use: commit --amend or rebase -i to squash WIP commits."
```

**Q3: Describe how you'd design a Git workflow for a 50-person DevOps team managing multi-cloud infrastructure**

Model Answer:
```
Considerations for large DevOps team:

1. Repository Strategy
   Monorepo vs. Polyrepo:
   
   For 50-person team: Monorepo (infrastructure/)
   Rationale:
     - Atomic infrastructure changes (all services + configs)
     - Unified CI/CD pipeline
     - Easier cross-team changes
     - Simplified dependency tracking
   
   Structure:
     infrastructure/
     ├── terraform/
     │   ├── aws/
     │   ├── gcp/
     │   └── azure/
     ├── kubernetes/
     ├── ansible/
     ├── scripts/
     ├── docs/
     └── .github/workflows/

2. Branching Strategy: GitHub Flow variant
   main:
     - Production-ready
     - All code reviewed
     - CI/CD tests passing
     - Protected

   develop:
     - Integration branch
     - Where features merge
     - Not protected (team can rebase)

   Feature branches:
     - type/description (feature/mfa-setup)
     - Short-lived (< 1 week)
     - Deleted after merge

3. Code Review Process
   Requirements:
     - 2+ reviewers (different domains)
     - CODEOWNERS (enforce cross-team review)
     - Terraform plan reviewed before merge
     - Kubernetes manifest validation
   
   CODEOWNERS file:
     terraform/aws/*     @team-cloud
     terraform/gcp/*     @team-infrastructure
     kubernetes/*        @team-platform
     ansible/*           @team-automation

4. CI/CD Integration
   Triggers:
     - PR: Run terraform validate, plan, tests
     - Push to main: Deploy to staging
     - Tag v*.*.*: Deploy to production
   
   Checks required before merge:
     ✓ Terraform validation passes
     ✓ Kubernetes manifests valid (kubeval)
     ✓ Documentation updated
     ✓ Security scanning (tfsec, trivy)
     ✓ Tests passing

5. Conflict Resolution Strategy
   Common conflicts in infrastructure:
     - Two teams modifying same variable
     - Dependency version conflicts
     - Resource name changes
   
   Process:
     1. Create merge-conflicts branch
        git checkout -b merge-conflict-resolution
        git merge feature/other-team-work
     2. Teams collaborate synchronously
        # Not async email, but direct discussion
     3. Resolve with both teams present
        git mergetool (visual resolution)
     4. Test together
        terraform plan (joint review)
     5. Merge to main
        git commit, git push

6. Infrastructure-as-Code Governance
   Pre-commit hooks:
     - terraform fmt (formatting)
     - terraform validate (syntax)
     - tfsec (security scan)
     - detect-secrets (no credentials)
   
   Post-merge checks:
     - tflint (advanced linting)
     - cost estimation (terraform-cost-estimation)
     - compliance scan (checkov)

7. Release Management
   Tagging strategy:
     v<MAJOR>.<MINOR>.<PATCH>
     v1.0.0 = Initial production
     v1.1.0 = New features added
     v1.0.1 = Critical patch
   
   Release process:
     1. Feature complete & merged to main
     2. Create release branch: git checkout -b release/v1.1.0
     3. Update version numbers & changelog
     4. Tag: git tag -a v1.1.0 -m "Release: v1.1.0"
     5. Push: git push origin v1.1.0
     6. CI/CD auto-deploys on tag

8. Emergency Procedures
   Critical bug in production:
     1. Hotfix branch from main
     2. Quick fix + tests
     3. Merge to main immediately
     4. Tag v1.0.1 (patch) + deploy
     5. Backport to develop
     6. Post-mortem within 24h
   
   Process documented: docs/deployment/HOTFIX.md

9. Team Communication
   Daily standups:
     - What merged yesterday
     - What's in code review
     - Any blocked changes
   
   Slack integration:
     - PR notifications
     - Merge notifications (who, what, when)
     - Deployment notifications
   
   Wiki/documentation:
     - Onboarding guide for new team members
     - Git workflow documentation
     - Troubleshooting conflicts guide
     - Emergency procedures

10. Metrics & Monitoring
    Track:
      - Time from PR open to merge
      - Merge conflicts per week
      - Rollback frequency
      - Time to deploy (main → prod)
    
    Improve:
      - Reduce conflicts → encourage master/develop sync
      - Faster reviews → rotate reviewers
      - Faster deploys → automate more

Scalability considerations:
  - Shallow clones for CI/CD speed
  - Sparse checkout for large repos
  - Scheduled garbage collection
  - Mirror repository for redundancy
  - Audit logging of all access
```

---

**Document Version:** 2.0  
**Last Updated:** March 18, 2026  
**Target Audience:** Senior DevOps Engineers (5-10+ years experience)  
**Related:** Part 1 - Git Architecture & Repository Setup  
**Prerequisites:** Foundational Git knowledge, Linux/Unix command line proficiency
