# Git Advanced Workflows & Large Repository Management
## Senior DevOps Engineer Study Guide

**Level:** Advanced (5-10+ years experience)  
**Focus:** Production-grade Git operations, team collaboration patterns, and enterprise repository strategies  
**Last Updated:** March 2026

---

## Table of Contents

### 1. Introduction
- [1.1 Overview of Topic](#overview-of-topic)
- [1.2 Why It Matters in Modern DevOps Platforms](#why-it-matters-in-modern-devops)
- [1.3 Real-World Production Use Cases](#real-world-production-use-cases)
- [1.4 Where It Appears in Cloud Architecture](#where-it-appears-in-cloud-architecture)

### 2. Foundational Concepts
- [2.1 Key Terminology](#key-terminology)
- [2.2 Architecture Fundamentals](#architecture-fundamentals)
- [2.3 Important DevOps Principles](#important-devops-principles)
- [2.4 Best Practices Framework](#best-practices-framework)
- [2.5 Common Misunderstandings](#common-misunderstandings)

### 3. Stashing & Workflows
- [3.1 Git Stash Fundamentals](#git-stash-fundamentals)
- [3.2 Stash Application Patterns](#stash-application-patterns)
- [3.3 Advanced Stash Management](#advanced-stash-management)
- [3.4 Stashing in Complex Workflows](#stashing-in-complex-workflows)

### 4. Advanced Diff & History Tools
- [4.1 Advanced Diff Operations](#advanced-diff-operations)
- [4.2 Git Log Analysis & Formatting](#git-log-analysis)
- [4.3 Blame & Regression Identification](#blame-and-regression)
- [4.4 Git Bisect & Problem Isolation](#git-bisect-problem-isolation)
- [4.5 Reflog & History Recovery](#reflog-and-history-recovery)

### 5. Undo & Recovery Techniques
- [5.1 Reset, Revert & Restore Taxonomy](#reset-revert-restore-taxonomy)
- [5.2 Safe Undo Patterns](#safe-undo-patterns)
- [5.3 Recovering Lost Commits](#recovering-lost-commits)
- [5.4 Production Recovery Procedures](#production-recovery-procedures)

### 6. Submodules & Monorepo Concepts
- [6.1 Git Submodule Architecture](#git-submodule-architecture)
- [6.2 Submodule Management at Scale](#submodule-management-at-scale)
- [6.3 Monorepo Strategies & Tradeoffs](#monorepo-strategies-and-tradeoffs)
- [6.4 Subtree Merge & Mixed Approaches](#subtree-merge-and-mixed-approaches)

### 7. Git Hooks
- [7.1 Hook Architecture & Types](#hook-architecture-and-types)
- [7.2 Client-Side Hooks for Quality](#client-side-hooks-for-quality)
- [7.3 Server-Side Hooks for Policy](#server-side-hooks-for-policy)
- [7.4 Hook Automation Framework](#hook-automation-framework)

### 8. Collaboration Models
- [8.1 Workflow Model Taxonomy](#workflow-model-taxonomy)
- [8.2 Gitflow & Release Workflows](#gitflow-and-release-workflows)
- [8.3 GitHub Flow & Trunk-Based Development](#github-flow-and-trunk-based)
- [8.4 Choosing Workflows for Organization](#choosing-workflows-for-organization)

### 9. Pull Requests & Code Reviews
- [9.1 Pull Request Mechanics & Patterns](#pull-request-mechanics)
- [9.2 Code Review Best Practices](#code-review-best-practices)
- [9.3 Merge Strategies in Pull Requests](#merge-strategies-in-pull-requests)
- [9.4 CI/CD Integration with PRs](#cicd-integration-with-prs)

### 10. Large Repository Handling
- [10.1 Performance Analysis & Optimization](#performance-analysis-and-optimization)
- [10.2 Git LFS & Object Management](#git-lfs-and-object-management)
- [10.3 Shallow & Partial Clones](#shallow-and-partial-clones)
- [10.4 Repository Splitting & Migration](#repository-splitting-and-migration)

### 11. Hands-on Scenarios
- [11.1 Emergency Production Hotfix Coordination](#emergency-production-hotfix)
- [11.2 Multi-Team Submodule Synchronization](#multi-team-submodule-sync)
- [11.3 Repository Splitting & History Rewriting](#repository-splitting-and-rewriting)
- [11.4 Migrating to Monorepo Architecture](#migrating-to-monorepo)

### 12. Interview Questions
- [12.1 Scenario-Based Questions](#scenario-based-questions)
- [12.2 Architecture & Design Questions](#architecture-design-questions)
- [12.3 Troubleshooting & Recovery Questions](#troubleshooting-recovery-questions)

---

## 1. Introduction

### 1.1 Overview of Topic {#overview-of-topic}

Advanced Git source control encompasses the sophisticated techniques, patterns, and tools that senior DevOps engineers leverage to manage complex development workflows at enterprise scale. While foundational Git knowledge covers basic branching and merging, this advanced study focuses on:

- **State Preservation & Recovery:** Using stash, reflog, and reset to manage workflow interruptions and mistakes
- **Historical Analysis:** Advanced tools for understanding code evolution, identifying regressions, and tracing changes
- **Collaboration Models:** Proven workflow architectures that scale across teams and time zones
- **Repository Architecture:** Managing monorepos, submodules, and distributed codebases in large organizations
- **Automation & Policy:** Git hooks and integrations for enforcing standards and enabling CI/CD pipelines
- **Scale & Performance:** Techniques for managing repositories with millions of commits and terabytes of data

This is not about learning Git commands—it's about understanding **Git as a strategic tool** for organizational software delivery.

### 1.2 Why It Matters in Modern DevOps Platforms {#why-it-matters-in-modern-devops}

Advanced Git mastery directly impacts core DevOps objectives:

**Velocity & Batch Size Reduction:**
- Efficient stashing and workflow patterns reduce context switching overhead
- Proper branching strategies (trunk-based development) enable faster deployment frequency
- Shallow clones and Git LFS reduce CI/CD pipeline execution times
- Code review workflows integrated with CI systems catch regressions before deployment

**Reliability & Blast Radius Control:**
- Understanding reset, revert, and reflog enables rapid recovery from deployments
- Hook-based quality gates prevent malformed commits from entering the pipeline
- Multi-team collaboration models reduce merge conflicts and integration failures
- Monorepo strategies provide atomic multi-service deployments

**Cost Optimization:**
- Sparse checkout and partial clone reduce storage and bandwidth costs
- Efficient object packing reduces storage footprints
- Repository splitting prevents monolithic growth that impacts all engineers

**Auditability & Compliance:**
- Advanced git blame and log analysis support SOC2/HIPAA requirements
- Commit history preservation and reflog enable forensic analysis
- Hook automation enforces code signing, commit message standards, and branch protection
- Server-side hooks prevent unauthorized direct pushes

**Operational Excellence:**
- Disaster recovery procedures minimize MTTR for repository corruption
- Stash workflows reduce deployment day chaos
- Bisect automation identifies introducing commits of regressions
- Large repository handling prevents repository cloning and CI/CD timeouts

### 1.3 Real-World Production Use Cases {#real-world-production-use-cases}

**Microservices Platform Migration (Monorepo Transition)**

A fintech company with 47 microservices across 15 Git repositories needed to:
- Move to Bazel-based build system requiring monorepo structure
- Maintain full commit history for 5 years of development
- Migrate without breaking any developer workflows

**Solution:** Used `git subtree` merge to combine repositories, preserved histories, established trunk-based development with service-level CI/CD gates.

**Emergency 3AM Production Hotfix**

A mobile app backend experienced database corruption affecting 500K users. Requirements:
- Fix deployed to production within 15 minutes
- Avoid introducing regressions in parallel feature branches
- Maintain clean commit history for root cause analysis

**Solution:** Used `git stash` to preserve feature work, hotfixed on main branch, used `git reflog` + `git show` to correlate with monitoring alerts, rebased features post-deployment.

**Global Engineering Team Collaboration**

An organization with 200 engineers across 8 time zones needed:
- Asynchronous code review without synchronous meetings
- Prevention of merge conflicts drowning review process
- Audit trail of who approved what and when

**Solution:** GitHub Flow with required status checks, hooks enforcing signed commits, integration with JIRA and Slack for async notifications.

**Legacy Monolith Componentization**

A company wanted to extract a payment module from a 1.2GB monolithic Rails app:
- Preserve history of the extracted module
- Avoid corrupting the original repository
- Enable independent deployment of the extracted service

**Solution:** Used `git filter-repo` with sparse checkout, rebuilt the module repository with subset of history, established submodule relationship or monorepo merge path.

### 1.4 Where It Appears in Cloud Architecture {#where-it-appears-in-cloud-architecture}

Advanced Git operations touch every layer of cloud-native architecture:

```
┌─────────────────────────────────────────────────────────────┐
│                    Developer Workstations                    │
│              (Local Git, stash, rebase workflows)            │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│              Git Hosting Platform                            │
│         (GitHub, GitLab, Gitea, Bitbucket)                  │
│    - Branch protection + hook enforcement                   │
│    - Code review workflow orchestration                     │
│    - Large file handling (LFS, object storage)              │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│     CI/CD Pipeline Orchestration                            │
│  (Jenkins, GitLab CI, GitHub Actions, ArgoCD)               │
│    - Triggered by Git webhooks                             │
│    - Executing on shallow/partial clones                   │
│    - Running hook-equivalent checks in CI                  │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│           GitOps & Infrastructure Deployment                │
│    (ArgoCD, Flux, Jenkins, CloudFormation)                  │
│    - Syncing repo state to cluster state                   │
│    - Monorepo organization for multi-service deploys       │
│    - Submodule updates triggering infrastructure changes   │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│   Container Registry & Artifact Management                  │
│         (ECR, Docker Hub, Artifactory, Nexus)              │
│    - Tags sourced from Git commit history                 │
│    - Binary cache from Git LFS references                 │
└─────────────────────────────────────────────────────────────┘
                              ↓
┌─────────────────────────────────────────────────────────────┐
│         Production Deployment & Runtime                     │
│  (Kubernetes, Lambda, AppEngine, on-premises)              │
│    - Deployment reversions via Git reflog                 │
│    - Audit logs correlated with Git blame                 │
└─────────────────────────────────────────────────────────────┘
```

**Key Architecture Integration Points:**

| Layer | Git Integration | Why It Matters |
|-------|-----------------|----------------|
| Developer | Stash, rebase, hooks | Workflow efficiency & quality gates |
| Repository | Branching, tags, LFS | Collaboration & scale |
| CI/CD | Webhook hooks, partial clone | Build performance & automation |
| Deployment | GitOps sync, submodules | Infrastructure as code & reproducibility |
| Runtime | Reflog recovery, blame | Incident response & compliance |

---

## 2. Foundational Concepts

### 2.1 Key Terminology {#key-terminology}

Understanding precise terminology is essential for discussing advanced Git operations with teams and vendors.

**Plumbing vs. Porcelain**
- **Porcelain:** High-level, user-friendly commands (`git commit`, `git push`, `git merge`)
- **Plumbing:** Low-level, internal mechanism commands (`git cat-file`, `git hash-object`, `git write-tree`)
- **In Practice:** Senior engineers must understand plumbing to troubleshoot corruption and build automation

**Refspec & Remote Tracking**
- **Refspec:** Mapping rule between local branches and remote tracking branches (e.g., `refs/heads/main:refs/remotes/origin/main`)
- **Remote Tracking Branch:** Local representation of remote branch state (read-only unless explicitly pulled)
- **In Practice:** Refspecing enables selective syncing and security policies

**Commit Ancestry & DAG**
- **DAG (Directed Acyclic Graph):** Git's internal data structure representing commit relationships
- **Ancestry:** Parent-child relationships; expressed as `commit^` (first parent) or `commit~n` (nth generation ancestor)
- **Fast-Forward:** Merge when target branch is direct ancestor of source
- **In Practice:** DAG concepts essential for understanding bisect, rebase, and merge strategy

**Index (Staging Area) vs. Working Tree**
- **Working Tree:** Your actual files on disk
- **Index:** Staging area; the prepared snapshot to be committed next
- **In Practice:** Distinguishing these enables partial stash, selective reset, and fine-grained workflows

**Loose Objects vs. Packed Objects**
- **Loose:** Individual objects in `.git/objects` directory (slower, smaller initial size)
- **Packed:** Compressed in `.git/objects/pack` directory (faster, smaller final size)
- **In Practice:** During large repository operations, packing behavior impacts performance

**References & Symbolic References**
- **Ref:** Pointer to a commit SHA (e.g., branch, tag)
- **Symbolic Ref:** Reference that points to another reference (typically `HEAD`)
- **In Practice:** Understanding refs enables recovery via direct manipulation and automation

**Merge Commit vs. Fast-Forward vs. Rebase**
- **Merge Commit:** Creates explicit merge commit preserving both parents
- **Fast-Forward:** Advances branch pointer without creating merge commit
- **Rebase:** Replays commits on top of new base (rewrites history)
- **In Practice:** Strategy choice significantly impacts history readability and cherry-picking behavior

**Shallow Clone & Grafts**
- **Shallow Clone:** Clone with limited history (e.g., last N commits)
- **Graft:** Artificial boundary in history (legacy approach; replaced by partial clone)
- **In Practice:** Shallow clone for CI/CD performance; grafts for migrating repositories

**Object Database & Refs Database**
- **Git Object Database:** `.git/objects` containing commits, trees, blobs, tags
- **Refs Database:** `.git/refs` containing branch pointers
- **In Practice:** Separation enables recovery—refs recovery without object recovery is impossible but object recovery is possible without refs

---

### 2.2 Architecture Fundamentals {#architecture-fundamentals}

**The Three Trees Model**

At its core, Git workflow revolves around three conceptual "trees":

```
         HEAD (Committed)
              │
    Previous Commit State
              │
    ┌─────────┼─────────┐
    │         │         │
Working Tree  Index  Repository
 (Disk)    (Staging)  (Commits)
    │         │         │
    └─────────┴─────────┘
          Git Operations
```

**Content-Addressable Storage**

Git is fundamentally a **content-addressable filesystem**:

```
SHA1("blob 11\0Hello World") = d95679752134a2d9eb61dbd7b91c4bcc6cffb3ca

Key Insight: Same content = Same SHA
            Different content = Different SHA
            Guarantees data integrity
```

**Implications:**
- Cannot corrupt history without changing SHAs
- Identical files across clones have identical SHAs
- Any change anywhere changes all downstream SHAs

**Graph Reachability**

All Git operations depend on **graph reachability**:

```
HEAD → latest commit → previous → ... → initial commit

What can't be reached?
- Commits on deleted branches (still in reflog for 30 days)
- Commits orphaned by reset (in reflog, garbage collected after 30 days)

Why this matters:
- Reflog is your safety net (30 day default window)
- Aggressive garbage collection can permanently lose commits
```

**Branch Pointers vs. Commits**

Critical distinction often missed:

```
concept→ branch name → commit SHA (immutable)
                          ↓
                       Snapshot of project state
                       (unchanged forever)

Implication: Rebasing creates NEW commits with different SHAs
             Old commits still exist (reachable via reflog)
             Branch pointer moves to new commits
```

**Distributed vs. Centralized Operations**

Git's distributed nature shapes everything:

```
Centralized Model (SVN):
  Developer → Central Server → All history on one system
              (failure = disaster)

Git Distributed Model:
  Dev A ← ──→ Dev B (direct collaboration)
    ↓          ↓
  Dev A's   Dev B's
  Complete Complete
  Repo     Repo
    ↓          ↓
  Central Server (backup, not authority)

Implication: Losing a remote is recoverable; local repos have full history
```

---

### 2.3 Important DevOps Principles {#important-devops-principles}

**Principle 1: Auditability Over Convenience**

Advanced workflows often sacrifice convenience for auditability:

```
❌ Interactive Rebase (rewrites history)
✓ Regular commits + merge commits (full history visible)

Reasoning for senior teams:
- Root cause analysis depends on accurate history
- Compliance (SOC2, HIPAA, PCI-DSS) requires commit trails
- "Who changed what and when" must be verifiable
```

**Principle 2: Fail-Safe Defaults**

Production workflows default to safety over velocity:

```
❌ git push --force (easy but dangerous)
✓ git push origin feature/xyz (creates PR, triggers review)

Why for DevOps:
- Automation should prevent foot-guns, not require discipline
- Hooks enforce these defaults automatically
- "I was just moving fast" causes production incidents
```

**Principle 3: Atomic Operations**

Git changes should be atomic (all-or-nothing):

```
Problem: Three services in microservices platform need synchronized deployment
❌ Push service A → push service B → push service C (2/3 failure = disaster)
✓ Monorepo with all three in one commit (transaction-like semantics)

OR

✓ Submodule pointers updated atomically (if tool supports multi-repo transactions)
```

**Principle 4: Immutability & Traceability**

DevOps depends on facts, not opinions about what version is running:

```
Fact: Production is running commit abc123
Verification:
  - Git tag references commit abc123
  - Docker image digest references Git commit abc123
  - Deployment logs show deployed from commit abc123
  - Diff from previous prod: git show abc123
  
Never: "It should be this version" (no, verify it)
```

**Principle 5: Disaster Recovery Readiness**

Senior DevOps assumes failure:

```
Question: How long to restore from repository corruption?
❌ 4 hours (restore from backups, rebuild from scratch)
✓ 5 minutes (local clone has full history; reflog enabled; tested procedure)

Implementation:
- Regular drills testing recovery procedures
- Reflog with extended grace periods (default 30 days insufficient for large orgs)
- Mirror repositories in multiple geographic regions
- Signed commits prevent impersonation during recovery
```

**Principle 6: Scalability as Architecture**

What works for 5 developers breaks for 500:

```
Branching Strategy:
5 devs: Git flow (feature branches, release branches)
500 devs: Trunk-based (main branch only—can't manage 500 in-flight feature branches)

Repository Structure:
Single large team: Monorepo (atomic deploys)
Multiple autonomous teams: Polyrepo (independent cadence)
Hybrid with shared infrastructure: Monorepo with service-level CI/CD boundaries
```

---

### 2.4 Best Practices Framework {#best-practices-framework}

**The PEACE Framework for Advanced Git Operations**

Senior DevOps engineers use a decision framework:

```
P - Policy: What does your organization require?
E - Efficiency: What reduces toil and context switching?
A - Auditability: What ensures compliance and incident response?
C - Consistency: What prevents individual variation causing failures?
E - Escape Routes: What enables recovery when things break?
```

**Applied Example:**

```
Pull Request Policy Question: Require branch protection + status checks?

P (Policy):      HIPAA requires ability to identify all changes to patient data
E (Efficiency):   Status checks prevent "build breaks" before merge
A (Auditability): Branch protection creates audit trail of reviewers
C (Consistency):  All services follow same check (no exceptions)
E (Escape Routes): Protected branches prevent accidental force-push to main

Decision: IMPLEMENT universal branch protection with status checks
```

**Commit Message Best Practices for DevOps**

Standard format for senior teams:

```
<type>(<scope>): <subject>

<body>

<footer>

Examples:

feat(auth): implement OIDC support

- Added OIDC discovery endpoint
- Configured token validation with key rotation
- Updated documentation for operators

Fixes: JIRA-1234
Related: JIRA-5678
Breaking-Change: Legacy session tokens no longer supported
Reviewed-By: @security-team
Signed-Off-By: John Doe <john@company.com>
```

**Why each element matters:**
- **Type:** Enables automated changelog generation, semantic versioning
- **Scope:** Correlates with monorepo packages, services, or components
- **Subject:** Searchable history; 50 chars for git log --oneline
- **Body:** Context for future debugging; why not what
- **Footer:** Audit trail (reviewers, sign-off, issue correlation)

**Branch Naming Conventions**

Systematic taxonomy enables automation:

```
feature/<jira-ticket>-<description>     (e.g., feature/INFRA-4521-add-vault-rotation)
bugfix/<jira-ticket>-<description>      (e.g., bugfix/INFRA-4522-fix-race-condition)
hotfix/<service>-<ticket>               (e.g., hotfix/payment-api-CRIT-12345)
release/v<semver>                       (e.g., release/v2.14.3)
chore/<task>                            (e.g., chore/update-dependencies)
docs/<topic>                            (e.g., docs/deployment-procedures)

Enables:
- Automated CI/CD rules based on branch pattern
- Cleanup scripts to remove stale branches
- Blame/bisect scoping ("commits only to feature/* branches")
```

---

### 2.5 Common Misunderstandings {#common-misunderstandings}

**Misunderstanding #1: "Rebase = Clean History, Merge = Messy History"**

Actually: Rebase **destroys information**; merge **preserves it**.

```
Reality:
- Rebase rewrites history (creates new SHAs; old commits disappear from branch)
- Merge preserves complete causality graph (who merged what when, from which branches)
- Rebase is easier to read but makes forensics impossible
- Merge is complex to read but enables complete reconstruction

For DevOps:
- Production deployments should use merge commits (preserve causality)
- Feature branch cleanup can use rebase (information locally available)
- Never rebase anything in main/production branches
```

**Misunderstanding #2: "Force Push is Just Faster"**

Actually: Force push is manual conflict resolution that can corrupt shared repositories.

```
❌ Developer: "CI keep saying branch diverged? Just force push"
   Result: Overwrites colleague's commits; creates bugs in their local branch

✓ Correct: Fetch latest, rebase/merge properly, then push

Rule: git push --force requires explicit team authorization
```

**Misunderstanding #3: "Git Hooks Ensure Code Quality"**

Actually: Local hooks are suggestions; only server-side hooks are enforceable.

```
Developer workstation hooks:
  - Run linters, tests automatically
  - Can be bypassed with git commit --no-verify
  - Cannot prevent them disabling hook

Server-side hooks:
  - Enforce immutable policy
  - Cannot be bypassed
  - Reject non-conforming pushes before hitting main repository

Reality: Local hooks are UX/developer experience; server hooks are policy enforcement
```

**Misunderstanding #4: "Stash is Version Control"**

Actually: Stash is **temporary scratchpad**; not version control.

```
❌ Engineer: Uses stash instead of branches for long-term work
   Problem: Stashes disappear after 30 days of inactivity
   Result: Lost work

✓ Stash is for: Interruptions, context switching, temporary workaround testing
```

**Misunderstanding #5: "Monorepo = Must Have Single Deploy"**

Actually: Monorepo is organization strategy; deployment strategy is orthogonal.

```
Monorepo can have:
  - Single service deployment (deploy one service from multi-service repo)
  - Selective deployment (deploy only changed services)
  - Unified deployment (deploy all services together)

Strategy depends on:
- Dependency tree (tightly coupled → unified; loosely coupled → service-level)
- Team structure (single team → unified; many teams → service-level)
- SLA requirements (all-or-nothing vs. independent cadence)
```

**Misunderstanding #6: "Shallow Clone is Transparent"**

Actually: Shallow clone breaks many Git operations.

```
What works in shallow clone:    What doesn't:
  - log, show, diff              - blame beyond graft
  - checkout branches            - filter-repo rewriting
  - normal commits               - Complex rebases
  - status, add                  - merge from outside graft

For CI/CD:       ✓ use shallow clone (faster, sufficient for build)
For development: ❌ Never use shallow clone (breaks interactive workflows)
```

**Misunderstanding #7: "Merged Branches Should Be Deleted"**

Actually: Deleted branch pointers don't delete commits; commits remain garbage-collected after 30 days.

```
git branch -d feature/x    (deletes pointer, NOT commits)
git log --all              (still shows all commits)
git reflog                (can recover branch pointer)

Benefit of cleanup: Reduces branch clutter in UI
Danger of aggressive cleanup: No protection from mistakes

Standard practice: Delete merged branches; rely on reflog for recovery
```

---

## 3. Stashing & Workflows {#stashing--workflows}

### 3.1 Git Stash Fundamentals {#git-stash-fundamentals}

**Internal Working Mechanism**

Git stash is not a branch or formal reference—it's a **temporary commit stored outside the normal DAG**. Internally:

```
When you run: git stash push -m "msg"

Git executes:
1. Creates commit from current working tree + staging area
2. Stores commit in reflog: refs/stash (special reference)
3. Records parent commits for later reapplication
4. Resets HEAD to last committed state (cleans working tree)

Internal storage:
  .git/refs/stash → points to latest stash commit
  .git/logs/refs/stash → history of all stashes
  
Stash entry = { index_commit, working_tree_commit, untracked_files (maybe) }
```

**Architecture Role**

Stash serves as a **context-switching mechanism** in your local workflow:

```
┌────────────────────────────────────────────────┐
│ You're making Feature A changes                │
│ (3 files modified, 1 staged)                  │
└────────────────────────────────────────────────┘
                        ↓
            Urgent: Production hotfix needed!
                        ↓
┌──────────────────────────────────────────────────┐
│ git stash push -m "wip: feature A progress"    │
│                                                  │
│ Working tree cleaned; all changes saved safely │
└──────────────────────────────────────────────────┘
                        ↓
        Checkout hotfix branch, fix production
                        ↓
┌──────────────────────────────────────────────────┐
│ Hotfix deployed; back to Feature A work        │
│ git stash pop                                  │
│                                                  │
│ Working tree restored; Feature A context back │
└──────────────────────────────────────────────────┘
```

**Production Usage Patterns**

**Pattern 1: Deployment Day Coordination**
```
Pre-deployment checklist:
1. Developer A: git stash push -m "feature/auth partial work"
2. Developer B: git stash push -m "feature/cache investigation"
3. Pull deployment branch (guaranteed clean state)
4. Run full test suite (no interference from uncommitted changes)
5. Deploy with confidence
6. Post-deployment: restore stashes, continue work
```

**Pattern 2: Emergency Context Switching**
```
Normal workflow broken by:
  - Security incident requiring immediate investigation
  - Production alert requiring branch switch
  - Code review request requiring context change

Solution:
  $ git stash push -m "INCIDENT-001: saved for recovery"
  $ git checkout security-incident-branch
  $ [investigate, fix, deploy]
  $ git checkout feature-branch
  $ git stash pop
```

**Pattern 3: Cleanup Before Pulling**
```
You have local changes but upstream also changed.
Bad approach: git pull --force (destroys local changes)

Better:
  $ git stash
  $ git pull
  $ [resolve conflicts if any]
  $ git stash pop
  $ [resolve merge conflicts manually]
```

**DevOps Best Practices**

| Practice | Rationale |
|----------|-----------|
| Use descriptive stash names | `git stash push -m "ticket-name: what changed"` helps identify stashes weeks later |
| Stash with clean history before deploys | Ensures CI/CD has known state; prevents "works on my machine" |
| Set long stash expiration | Default 30 days too short for on-call scenarios; consider `git config gc.reflogExpire 6months` |
| Never commit stashed-then-forgotten code | Stash is temporary; anything >2 days should be in a branch |
| Include untracked files when needed | `git stash push -u` for complete context preservation |
| Document stash recovery procedures | Post-mortem: "How many stashes were lost due to machine crash?" |

**Common Pitfalls**

| Pitfall | Problem | Solution |
|---------|---------|----------|
| **Stash Amnesia** | Applied stash 2 weeks ago, forgot `git stash pop` runs immediately after → lost context | `git stash apply` (doesn't remove), then manually `git stash drop` after verifying |
| **Stash Conflicts** | `git stash pop` fails if HEAD has conflicting changes | Handle merge conflicts in working tree, then `git stash drop` |
| **Untracked Files Lost** | Untracked files not in stash → forgotten after cleanup | Always use `git stash push -u` to include untracked files |
| **Corrupted Stash Index** | Database corruption → all stashes inaccessible | Mirror repositories + regular reflog backups mitigate |
| **Stash as Version Control** | Treating stash as long-term storage → lost after 30 days garbage collection | Use branches for anything that lasts >1 day |

### 3.2 Stash Application Patterns {#stash-application-patterns}

**Apply vs. Pop vs. Branch**

```
Scenario: You have stash@{0} = "WIP: Redis cache changes"

❌ git stash pop
   - Removes stash entry immediately
   - If conflicts occur, merge conflicts left in working tree
   - If stash lost during pop, completely gone
   
✓ git stash apply
   - Keeps stash entry (safe for retry)
   - Apply changes to working tree
   - Manually resolve conflicts
   - Manually git stash drop when satisfied

✓ git stash branch feature/redis-restore
   - Creates NEW branch from stash commit
   - Preserves original stash
   - Enables full Git workflow on stashed work
   - Best for significant stashed work that needs review
```

**Production Example:**

```bash
#!/bin/bash
# Stash Recovery Script for Deployment Rollback

STASH_NAME="pre-deployment-$(date +%Y%m%d-%H%M%S)"

# Safety: Create stash from current changes
git stash push -m "$STASH_NAME"

# Attempt rollback
if ! git reset --hard origin/stable; then
    echo "Rollback failed; restoring stashed changes"
    git stash pop  # Restore work
    exit 1
fi

# Rollback succeeded
echo "Deployed from stable; work stashed as: $STASH_NAME"
git stash drop  # Safe to remove since deploy succeeded
```

### 3.3 Advanced Stash Management {#advanced-stash-management}

**Stash Variants & Options**

```bash
# Basic stashing
git stash                              # Stash staged + unstaged (not untracked)
git stash push -m "message"            # Named stash
git stash push -m "msg" file1 file2    # Stash specific files only

# Include/exclude patterns
git stash push -u                      # Include untracked files
git stash push --keep-index            # Stash only unstaged changes (keep index)
git stash push --staged                # Stash only staged changes
git stash push --include-untracked --all  # Everything: staged, unstaged, untracked

# Viewing stashes
git stash list                         # Show all stashes
git stash show stash@{0}               # Summary of stash changes
git stash show -p stash@{0}            # Full diff of stash
git stash show -p --stat stash@{0}     # Stats of stash

# Advanced operations
git stash pop stash@{2}                # Apply specific stash (not latest)
git stash apply --index stash@{0}      # Restore staging area state
git stash branch feature/from-stash    # Create branch from stash
git stash drop stash@{1}               # Delete specific stash
git stash clear                        # Delete all stashes (dangerous!)
```

**Practical Workflow:**

```bash
# Scenario: You're on feature/api-auth with changes staged and unstaged
# You need to check hotfix/database-migration without losing context

# Step 1: See what you have
$ git status
On branch feature/api-auth
Changes to be committed:
  modified:   src/auth.go (staged)
Changes not staged for commit:
  modified:   src/middleware.go (unstaged)
Untracked files:
  README_AUTH.md

# Step 2: Stash everything with named save
$ git stash push -u -m "auth-feature: staged auth.go, unstaged middleware.go, draft docs"

# Step 3: Verify clean state
$ git status
On branch feature/api-auth
nothing to commit, working tree clean

# Step 4: Switch to hotfix
$ git checkout hotfix/database-migration
$ [fix database issue]
$ git commit -m "fix: migrate schema v3→v4"
$ git push origin hotfix/database-migration

# Step 5: Back to feature work
$ git checkout feature/api-auth

# Step 6: Restore with index (restores staging area)
$ git stash pop --index stash@{0}

# Step 7: Verify restoration
$ git status
On branch feature/api-auth
Changes to be committed:
  modified:   src/auth.go
Changes not staged for commit:
  modified:   src/middleware.go
Untracked files:
  README_AUTH.md
```

### 3.4 Stashing in Complex Workflows {#stashing-in-complex-workflows}

**Multi-Stash Coordination**

```
Real Scenario: DevOps team with 3 engineers, 4 in-flight features, 1 production incident

Problem: Everyone has uncommitted work; incident requires immediate focus

Solution: Coordinated stashing + incident response

┌─────────────────────────────────────────────────────┐
│ Engineer A (feature/k8s-autoscaling)               │
│ $ git stash push -m "A: k8s-metrics-collector"    │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Engineer B (feature/logging-restructure)           │
│ $ git stash push -m "B: centralized-JSON-format"  │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│ Engineer C (feature/cert-rotation)                 │
│ $ git stash push -m "C: cert-lifecycle-manager"   │
└─────────────────────────────────────────────────────┘

All pull main-branch → git checkout incident-branch
All collaborate on incident fix
Incident resolved → Deploy

Back to feature work:
┌─────────────────────────────────────────────────────┐
│ Each engineer:                                      │
│ $ git checkout feature/X                           │
│ $ git stash pop                                    │
│ Resume work with full context                     │
└─────────────────────────────────────────────────────┘
```

**Stash Integration with CI/CD**

```bash
#!/bin/bash
# Pre-deployment validation: Ensure clean stashes (no orphaned work)

# Check if any stashes older than 2 days exist
THRESHOLD_SECONDS=$((2 * 24 * 60 * 60))
CURRENT_TIME=$(date +%s)

git stash list | while read line; do
    STASH_NAME=$(echo "$line" | cut -d: -f1)
    STASH_TIME=$(git stash show -p "$STASH_NAME" | grep "Date:" | head -1 | date -f - +%s)
    AGE=$((CURRENT_TIME - STASH_TIME))
    
    if [ $AGE -gt $THRESHOLD_SECONDS ]; then
        echo "WARNING: Old stash detected: $STASH_NAME (age: $((AGE/3600)) hours)"
        echo "  You should either:"
        echo "  - Commit this work to a branch"
        echo "  - Manually git stash pop and review"
        echo "  - git stash drop if abandoned"
    fi
done

# Fail deployment if old stashes detected
if [ $(git stash list | wc -l) -gt 3 ]; then
    echo "ERROR: Too many stashes detected. Clean up before deployment."
    exit 1
fi

echo "Stash check passed: Ready for deployment"
```

---

## 4. Advanced Diff & History Tools {#advanced-diff--history-tools}

### 4.1 Advanced Diff Operations {#advanced-diff-operations}

**Internal Working Mechanism**

Git diff compares **Git objects**, not files:

```
git diff [source] [target]

Git executes:
1. Resolves [source] and [target] to commits (or trees/blobs)
2. Walks both object DAGs
3. Compares tree objects at each level
4. Produces bytewise diff of differing blobs
5. Formats output according to requested --[format]

Performance implications:
- Comparing indexing files: expensive (n objects to compare)
- Larger files: expensive (bytewise diff on size)
- Binary files: requires binary diff algorithm (slow)
```

**Diff Algorithms & Trade-offs**

```bash
# Default (Myers algorithm): Good balance, slower on some rearrangements
git diff

# Patience algorithm: Better at detecting moved blocks, slower
git diff --patience

# Histogram: Fast approximation, fewer false positives
git diff --histogram

# Word diff: Compare word-by-word instead of line-by-line
git diff --word-diff

# Whitespace handling
git diff -w              # Ignore all whitespace
git diff -b              # Ignore changes in whitespace amount
git diff --ignore-space-at-eol  # Ignore trailing whitespace

# Rename detection
git diff -M 80%          # Detect renames >80% similarity
git diff -C 80%          # Detect copies >80% similarity
git diff -M90% -C90%     # Strict rename/copy detection
```

**Production Usage Patterns**

**Pattern 1: Pre-Commit Review**

```bash
# Before committing, verify what you're actually committing
$ git diff --cached --stat
 src/auth.go         | 45 +++++++++++++++++-------
 src/middleware.go   | 12 +++----
 2 files changed, 40 insertions(+), 17 deletions

# See full changes
$ git diff --cached --color-words
```

**Pattern 2: Regression Analysis**

```bash
# When: "Performance degraded after commit abc123"
# Find: What exactly changed that could cause it

$ git diff abc123~1..abc123 --stat
 infra/db/connection_pool.go | 23 +++++-------
 cache/redis_client.go       | 18 +++++---
 2 files changed, 20 insertions(+), 21 deletions

$ git show abc123:infra/db/connection_pool.go > /tmp/old.go
$ git show abc123~1:infra/db/connection_pool.go > /tmp/new.go
$ diff -u /tmp/old.go /tmp/new.go | less
```

**Pattern 3: Multi-Commit Change Tracking**

```bash
# What changed across multiple merge requests to main?
$ git diff v2.5.0..v2.6.0 --stat

# What files are most volatile (changed most)?
$ git diff v2.5.0..v2.6.0 --name-status | cut -f2 | sort | uniq -c | sort -rn

# Changed most: monitoring/prometheus.yaml (12 changes)
# Changed most: infra/terraform/main.tf (8 changes)
```

**DevOps Best Practices**

```bash
#!/bin/bash
# Pre-merge validation: Ensure diff is small and reviewable

DIFF_STATS=$(git diff --stat main..feature/branch | tail -1)
FILES_CHANGED=$(echo "$DIFF_STATS" | awk '{print $1}')
INSERTIONS=$(echo "$DIFF_STATS" | awk '{print $4}')
DELETIONS=$(echo "$DIFF_STATS" | awk '{print $6}')

# Heuristic: Large diff = harder review = more bugs
if [ "$FILES_CHANGED" -gt 30 ] || [ "$INSERTIONS" -gt 1000 ]; then
    echo "ERROR: Diff too large for reliable review"
    echo "  Files changed: $FILES_CHANGED (threshold: 30)"
    echo "  Insertions: $INSERTIONS (threshold: 1000)"
    echo "  Actions: Split feature into smaller PRs or reduce scope"
    exit 1
fi

echo "Diff check passed"
```

**Common Pitfalls**

| Pitfall | Problem | Solution |
|---------|---------|----------|
| **Large Diffs Hiding Bugs** | >1000 line commits impossible to review thoroughly | Split into logical units; enforce max sizes in CI |
| **Whitespace Mess** | Format change + logic change indistinguishable | `git diff -w` to ignore whitespace during review |
| **Accidental Binary Files** | Generated files cause huge diffs | Add to `.gitignore`; use Git LFS for necessary binaries |
| **Renames Not Detected** | File moved + modified shows as delete + add (confusing) | Use `-M` flag to detect renames; ensure minimum similarity % |
| **Incomplete Diff Context** | `-U3` (3 lines context) insufficient for understanding | Use `-U10` or `git log -p --full-history` for context |

### 4.2 Git Log Analysis & Formatting {#git-log-analysis}

**Log Formatting for DevOps**

```bash
# Customizable format (for parsing by scripts)
git log --format='%h %an %ad %s' --date=short

# Oneline (human readable)
git log --oneline

# Detailed with refs
git log --oneline --graph --all --decorate

# For CI/CD: Machine-readable JSON
git log --format='%H %an %ae %ad %s' --date=iso-strict

# Statistics: Who commits most?
git log --format='%an' | sort | uniq -c | sort -rn

# Statistics: What time do commits happen? (detect timezone issues)
git log --format='%ai %an' | awk '{print $2}' | sort | uniq -c
```

**Production Usage Patterns**

**Pattern 1: Release Notes Generation**

```bash
#!/bin/bash
# Generate release notes from git commit history

VERSION=$1
PREVIOUS_VERSION=$(git tag | sort -V | tail -2 | head -1)
CURRENT_VERSION=$VERSION

echo "# Release Notes $CURRENT_VERSION"
echo ""
echo "## Changelog"
echo ""

git log --format='- %s (by %an)' $PREVIOUS_VERSION..$CURRENT_VERSION | \
    grep -E '^- (feat|fix|perf):' | \
    sort | uniq

echo ""
echo "## Commits"
git log --format='%H %h %s' $PREVIOUS_VERSION..$CURRENT_VERSION | head -20
```

**Pattern 2: Audit Trail Search**

```bash
# DevSecOps: Find all commits that touched sensitive files

git log --name-status --pretty=format:'%H %an %ad %s' --date=iso -- \
    'src/config/secrets*.yaml' \
    'src/auth/*.go' \
    'infra/terraform/aws_keys.tf'

# Output:
# abc def@company.com 2024-01-15 fix: update api key rotation
#   M src/config/secrets.yaml

# Use for: Compliance reports, incident investigation, access reviews
```

**Pattern 3: Blame-Based Analysis**

```bash
# Who's responsible for oldest unfixed bugs?
git log --reverse --format='%h %an %ad' --date=short -- src/bug-file.go | head -1

# Output: abc john@company.com 2019-03-15
# Interpretation: John's 2019 commit introduced this bug!
```

**DevOps Best Practices**

```bash
# Log Output Standards: Machines Need Predictability

# ✓ Parseable format for automation
LAST_RELEASE=$(git log --format='%h' --grep='Release v' -n 1)

# ✗ Free-form format hard to parse
LAST_RELEASE=$(git log | grep -i "released" | head -1)  # Fragile!

# ✓ Consistent date format for metrics
git log --format='%ai' | sort

# ✗ Locale-dependent date format
git log --format='%ar'  # "2 weeks ago" changes with locale!

# ✓ Track commit distribution for scaling insights
git log --format='%an' | sort | uniq -c | sort -rn

# Shows: top contributors (need code review spread?)
```

### 4.3 Blame & Regression Identification {#blame-and-regression}

**Git Blame Mechanics**

```
git blame [filename]

Walkthrough:
1. Start at HEAD commit
2. For each line in current state: trace back to when it was introduced
3. For each line: find commit that added/modified it
4. Output: { commit SHA, author, timestamp, line content }

Graphical view reveals:
- Who wrote each line
- When changes introduced
- Concentrated change areas (many lines same color = one commit)
- Long-stable vs frequently-changing areas
```

**Production Usage Patterns**

**Pattern 1: Regression Root Cause**

```bash
# Scenario: Performance degraded; suspicious line in connection_pool.go

$ git blame src/db/connection_pool.go | grep "retry_attempts"
abc def john@company.com (2024-01-15 14:23:45) 142:   if retry_attempts > 10 {

# Find what that commit was
$ git show abc --stat
commit abcdef
Author: john@company.com
Date: 2024-01-15 14:23:45 +0000
    perf: increase retry limit for unreliable networks

# Check if this is recent (suspicious) or stable
$ git log -p abc -- src/db/connection_pool.go

# If recent change → likely cause of regression
# Reverse with: git revert abc
```

**Pattern 2: Distributed Blame (Multi-file Analysis)**

```bash
#!/bin/bash
# Find which files changed most recently (highest regression risk)

for file in $(git ls-files | grep -E '\.(go|py|js)$'); do
    LAST_CHANGE=$(git log -1 --format='%ai' -- "$file" | cut -d' ' -f1)
    echo "$LAST_CHANGE $file"
done | sort -r | head -20

# Output shows: Recently modified files = higher regression probability
# Schedule these for extra testing before deployment
```

### 4.4 Git Bisect & Problem Isolation {#git-bisect-problem-isolation}

**Bisect Algorithm (Binary Search)**

```
Problem: Bad behavior introduced somewhere in last 100 commits
Time to find manually: ~100 tests
Time with bisect: ~7 tests (log₂ 100)

Bisect: Binary search through commit history

commits: [v1.0] ----50 commits---- [v2.0]  (v1.0 good, v2.0 bad)

Bisect round 1: Test   [v1.0] ----25---- [mid] ----25---- [v2.0]
                       Is [mid] good or bad?
                       
If [mid] is good:   Problem in second half
If [mid] is bad:    Problem in first half

Repeat ~7 times: Converge on exact commit
```

**Production Usage:**

```bash
# Automated bisect: Find regression in performance metric

git bisect start v1.0 v2.0

# Automated test: Returns 0 (good) or 1 (bad)
while git bisect next; do
    # Run benchmark
    LATENCY_MS=$(./benchmark.sh | grep "p99" | awk '{print $2}')
    
    if [ ${LATENCY_MS%.*} -gt 150 ]; then
        git bisect bad
    else
        git bisect good
    fi
done

# Output: Exact commit causing regression
# Example: abc defines "use_new_cache_strategy = true"
# Action: Investigate abc, revert if bug, tune parameters if intended
```

**Bisect Script for DevOps:**

```bash
#!/bin/bash
# bisect-perf.sh: Automated performance regression identification

BRANCH=$1
BASELINE_LATENCY=$(git show origin/main:benchmark.results | grep "p99" | awk '{print $2}')
THRESHOLD=1.2  # 20% performance degradation threshold

echo "Baseline latency: ${BASELINE_LATENCY}ms"
echo "Threshold: 20% worse = $((BASELINE_LATENCY * THRESHOLD))ms"

git bisect start "$BRANCH" origin/main

while git bisect next 2>/dev/null; do
    # Rebuild and test
    make clean && make bench > /tmp/bench.log 2>&1
    
    CURRENT_LATENCY=$(grep "p99" /tmp/bench.log | awk '{print $2}')
    WORSE_THAN=$(echo "$CURRENT_LATENCY > $BASELINE_LATENCY * $THRESHOLD" | bc)
    
    if [ "$WORSE_THAN" -eq 1 ]; then
        echo "[$CURRENT_LATENCY ms] BAD - Regression detected"
        git bisect bad
    else
        echo "[$CURRENT_LATENCY ms] GOOD - Within threshold"
        git bisect good
    fi
done

git bisect reset
```

### 4.5 Reflog & History Recovery {#reflog-and-history-recovery}

**Reflog Architecture**

```
Reflog = "Reference Log" = Change history of all refs

Stored in: .git/logs/

Structure:
  refs/heads/main:
    abc HEAD@{0}  # Latest state
    def HEAD@{1}  # State 5 commits ago
    ghi HEAD@{2}  # State before rebase
    ...

Access:
  HEAD@{0}       # Latest
  HEAD@{5}       # 5 operations ago
  HEAD@{15 minutes ago}  # 15 minutes ago
  
  main@{0}
  main@{1}
  ... same for any branch
```

**Production Example: Undo Destructive Reset**

```bash
# Accidental destruction
$ git reset --hard origin/main
# Realizes: "Wait, I had uncommitted work!"

# Recover: Use reflog
$ git reflog
abc def HEAD@{0}: reset: moving to origin/main
ghi jkl HEAD@{1}: commit: add cache layer
mnop qrs HEAD@{2}: checkout: moving from feature/cache to main

# Restore to state before reset
$ git reset --hard HEAD@{1}
# or
$ git reset --hard ghi

# Working tree restored!
$ git status
On branch feature/cache
Changes not staged for commit:
  modified: src/cache.go
```

**Reflog Best Practices**

```bash
# Increase reflog retention (default 30 days too short for large teams)

# Set globally:
git config --global gc.reflogExpire "6 months"
git config --global gc.reflogExpireUnreachable "6 months"

# Verify:
$ git config --list | grep reflog
core.reflogexpire=6 months
core.reflogexpireunreachable=6 months

# Recovery implications:
# - 30 days → covers 1 month of mistakes
# - 6 months → covers 6 months of mistakes; more triage required
# - Forever (keep all) → repository bloats; requires manual cleanup
```

---

## 5. Undo & Recovery Techniques {#undo--recovery-techniques}

### 5.1 Reset, Revert & Restore Taxonomy {#reset-revert-restore-taxonomy}

**Three Tools, Three Different Operations**

```
Scenario: You made bad commit abc123

Tool         What it does          Result for working tree   Modifies history?
──────────────────────────────────────────────────────────────────────────
git reset    Move HEAD backwards   Changes to uncommitted    YES (rewrites)
git revert   Create opposite       Unchanged; makes new      NO (adds commit)
git restore  Discard local changes Working tree only         NO
```

**Internal Mechanisms**

```
git reset --hard abc
  1. Moves HEAD to abc
  2. Resets index to match abc
  3. Resets working tree to match abc
  4. ⚠️ Destroys all uncommitted changes
  
git revert abc
  1. Creates new commit that undoes abc
  2. Leaves HEAD moved forward (not backward)
  3. Full history preserved (nothing destroyed)
  4. Safe for shared branches

git restore --staged file.txt
  1. Resets index entry for file.txt
  2. Leaves working tree unchanged
  3. File remains modified but unstaged
  4. No history involved
```

**Reset Modes Explained**

```
Commit tree:  [HEAD] → [A] → [B] → [C] (current state)
Want to return to [B]

$ git reset --soft HEAD~1
  Result: HEAD → [B], staging area has [C] changes, working tree has [C]
  Use case: Rewrite last commit (split into multiple, combine with previous)
  
$ git reset --mixed HEAD~1 (default)
  Result: HEAD → [B], staging area cleared, working tree has [C]
  Use case: Uncommit changes; keep them for re-staging and recommitting
  
$ git reset --hard HEAD~1
  Result: HEAD → [B], staging area cleared, working tree cleared
  Use case: Destroy commit and all changes completely
  Risk: ⚠️ Irreversible if not in reflog!
```

**Production Usage Patterns**

**Pattern 1: Oops, Committed to Wrong Branch**

```bash
# Current: On main; made 3 commits that should be on feature/xyz

# Step 1: Create the feature branch from current state
$ git branch feature/xyz

# Step 2: Rewind main to before those commits
$ git reset --hard HEAD~3

# Step 3: Switch to feature branch (has the 3 commits)
$ git checkout feature/xyz

# Step 4: Verify
$ git log --oneline | head -3  # See the 3 commits
$ git checkout main && git log --oneline | head -3  # Main is clean
```

**Pattern 2: Accidental Commit to Main (Must Revert in Shared Repo)**

```bash
# Current: Committed bad change to shared main branch
# Problem: If you reset, others pulling get conflicts

# ✓ Correct approach:
$ git revert abc123

# This creates new commit undoing abc123
# Everyone pulling gets clear message: "Change was reverted"
# History preserved for audit

# Verify:
$ git show  # See revert commit that undoes abc123
```

### 5.2 Safe Undo Patterns {#safe-undo-patterns}

**Golden Rule: Always Use Revert for Shared Branches**

```
        ┌─── Your local development branch
        │    (use reset, rebase, history rewriting)
        │
main ───┴─── Shared with team
               (use revert, regular commits)
               (history is permanent audit trail)
```

**Safe Undo Workflow Script**

```bash
#!/bin/bash
# safe_undo.sh: Interactive undo with rollback protection

COMMIT=$1

if [ -z "$COMMIT" ]; then
    echo "Usage: ./safe_undo.sh <commit-sha>"
    exit 1
fi

# Check: Is this commit reachable from main?
if ! git merge-base --is-ancestor "$COMMIT" main; then
    echo "WARNING: Commit not in shared history"
    echo "Safe to use git reset (local only)"
    read -p "Proceed with reset? (y/n) "
    [ "$REPLY" = "y" ] && git reset --hard "$COMMIT"
    exit $?
fi

# Commit is in shared history
echo "Commit is in shared main branch"
echo "Creating revert (safe for team)"
git revert "$COMMIT"

# Show what happened
echo "Revert created. New commit:"
git log -1 --oneline
```

### 5.3 Recovering Lost Commits {#recovering-lost-commits}

**Commit Recovery Decision Tree**

```
Lost commit abc123?

Did you commit it?
  NO → Can't recover (never in Git)
  YES → Continue...
  
Is it in reflog?
  YES → git reset --hard abc123
  NO → Continue...
  
Is it in git fsck orphaned objects?
  YES → git reset --hard <found-sha>
  NO → Continue...
  
Is it in git gc backups?
  YES → Restore from backup, rebuild reflog
  NO → Commit is permanently lost
```

**Recovery Procedure: Multi-Step**

```bash
#!/bin/bash
# recover_lost_commit.sh

echo "Step 1: Check reflog directly accessible"
if git reflog | grep -q "$1"; then
    echo "Found in reflog!"
    git reset --hard "$1"
    exit 0
fi

echo "Step 2: Search reflog for dangling commits"
git reflog expire --all --expire=now  # Force reflog check
git reflog | head -20

echo "Step 3: Find all reachable commits"
git show "$1" 2>/dev/null && echo "Commit still exists in objects" || echo "Commit not in object DB"

echo "Step 4: Find orphaned objects"
git fsck --no-reflogs | grep "dangling commit" | head -10

echo "Step 5: Last resort - check backup repositories"
if [ -n "$GIT_MIRROR_REPO" ]; then
    git -C "$GIT_MIRROR_REPO" show "$1" 2>/dev/null && echo "Found in mirror!"
fi
```

### 5.4 Production Recovery Procedures {#production-recovery-procedures}

**Incident Response: "Main Branch is Broken"**

```bash
#!/bin/bash
# declare_incident.sh: Automated incident response

INCIDENT_ID=$(date +%s)
BACKUP_BRANCH="incident-backup-$INCIDENT_ID"

# Step 1: Preserve current state
git branch "$BACKUP_BRANCH"
echo "Backup branch created: $BACKUP_BRANCH"

# Step 2: Identify last known good state
LAST_DEPLOYMENT="$(git log --grep='Deployed to prod' --oneline | head -1 | cut -d' ' -f1)"
LAST_TEST_PASS="$(git log --grep='CI_PASS' --oneline | head -1 | cut -d' ' -f1)"

# Step 3: Decide rollback point
if [ -n "$LAST_DEPLOYMENT" ]; then
    ROLLBACK_POINT=$LAST_DEPLOYMENT
else
    ROLLBACK_POINT=$LAST_TEST_PASS
fi

echo "Rolling back to: $ROLLBACK_POINT"

# Step 4: Reset with extreme caution
git reset --hard "$ROLLBACK_POINT"

# Step 5: Verify state
if git log -1 --oneline | grep -q "Deployed"; then
    echo "✓ Rollback successful; returning to known good state"
    git push origin main --force-with-lease  # Safer than --force
    exit 0
else
    echo "✗ Rollback verification failed; restoring backup"
    git reset --hard "$BACKUP_BRANCH"
    exit 1
fi
```

**Corruption Recovery: "Object Database Corrupted"**

```bash
#!/bin/bash
# recover_from_corruption.sh

echo "Running object database diagnostic"

# Step 1: Identify corruption
if ! git fsck --full; then
    echo "Object database has errors detected"
    
    # Step 2: Try automatic repair
    git reflog expire --all --expire=now
    git gc --aggressive --prune=now
    
    # Step 3: Verify repair
    if git fsck --full; then
        echo "✓ Automatic repair successful"
        exit 0
    fi
fi

# Step 4: Manual recovery from backup
if [ -d "$BACKUP_GIT_DIR" ]; then
    echo "Restoring from backup: $BACKUP_GIT_DIR"
    rm -rf .git
    cp -r "$BACKUP_GIT_DIR" .git
    git fsck --full
    exit $?
fi

echo "✗ Unable to repair; manual intervention required"
exit 1
```

---

## 6. Submodules & Monorepo Concepts {#submodules--monorepo-concepts}

### 6.1 Git Submodule Architecture {#git-submodule-architecture}

**Submodule Mechanics**

```
Submodule = Git repository nested within another Git repository

Structure:

Parent Repository:
  ├── .gitmodules           (configuration file)
  ├── .git/config           (submodule entries)
  ├── app.go
  └── vendor/logging        ← submodule directory
      └── .git → (points to actual submodule .git)

.gitmodules file:
  [submodule "vendor/logging"]
    path = vendor/logging
    url = https://github.com/company/logging.git

How Git tracks submodules:
  Commit abc123:
    - Parent repo has normal files
    - Submodule tracked as { path, commit-sha }
    - Parent repository stores: "vendor/logging@defeef"
    - Does NOT store submodule's full commit
    - Submodule commit ref enables reproducibility

Initialization workflow:
  git submodule update --init --recursive
    1. Reads .gitmodules
    2. For each submodule: clones from configured URL
    3. For each submodule: checks out stored commit SHA
    4. Result: All dependencies at known versions
```

**Submodule vs. Git LFS: Key Difference**

```
git submodule:
  - Full Git repository nested in another
  - Versioned independently (submodule has own commit history)
  - Heavy: clones entire history
  - Use case: Shared libraries, frameworks, code dependencies

git lfs (Large File Storage):
  - Stores large binary files in LFS server
  - Parent repo references via hash (not full history)
  - Light: clones only needed files
  - Use case: Large binaries, media, models
```

**Production Usage Patterns**

**Pattern 1: Shared Library Management**

```
Company structure:
  - microservice-api (public API)
  - microservice-queue (async jobs)
  - microservice-worker (worker processes)
  
All three depend on: shared-auth library (version controlled separately)

Solution: submodule

microservice-api/.gitmodules:
  [submodule "vendor/shared-auth"]
    path = vendor/shared-auth
    url = https://github.com/company/shared-auth.git

When shared-auth releases v2.3.0, each service updates:
  $ cd microservice-api
  $ cd vendor/shared-auth
  $ git checkout v2.3.0
  $ cd ../..
  $ git add vendor/shared-auth  (commits "vendor/shared-auth@v2.3.0" pointer)
  $ git commit -m "chore: update shared-auth to v2.3.0"
```

### 6.2 Submodule Management at Scale {#submodule-management-at-scale}

**Multi-Submodule Synchronization**

```bash
#!/bin/bash
# sync_all_submodules.sh: Update all submodules to latest tags

# Scenario: 15 microservices depending on 5 shared libraries
# Each library publishes new versions; need coordinated update

LIBRARIES=(
    "vendor/shared-auth"
    "vendor/shared-logging"
    "vendor/shared-metrics"
    "vendor/shared-validation"
    "vendor/shared-crypto"
)

for service in microservice-{api,worker,queue}; do
    echo "Updating $service submodule dependencies..."
    
    cd "$service"
    for lib in "${LIBRARIES[@]}"; do
        if [ -d "$lib" ]; then
            cd "$lib"
            LATEST_TAG=$(git describe --tags "$(git rev-list --tags --max-count=1)")
            echo "  $lib: $LATEST_TAG"
            git fetch --all --tags
            git checkout "$LATEST_TAG"
            cd ../..
        fi
    done
    
    # Commit submodule pointer updates
    git add --all
    git commit -m "chore: update shared library dependencies"
    cd ..
done
```

**Submodule Pitfalls & Solutions**

| Pitfall | Problem | Solution |
|---------|---------|----------|
| **Detached HEAD** | `git submodule update` checks out commit SHA (not branch) | Document the workflow; use `git checkout <branch>` explicitly |
| **Stale Submodule Refs** | Team member forgets `git submodule update --init --recursive` | Add pre-commit hook: mandatory submodule init |
| **Conflicting Updates** | Two PRs update same submodule to different commits | Rebase strategy; last PR wins; requires coordination |
| **Large Clone Time** | 10 submodules with full history = 30+ minute clone | Use shallow clone: `git clone --depth 1 --recurse-submodules` |
| **Submodule Commit History Loss** | Submodule repo deleted; pointers become dangling | Mirror all submodule repositories; restore from backup |

### 6.3 Monorepo Strategies & Tradeoffs {#monorepo-strategies-and-tradeoffs}

**Monorepo Architecture Decision Matrix**

```
Question: Single repo or multiple repos?

Monorepo pros:
  ✓ Atomic commits (all services updated together)
  ✓ Shared library updates visible immediately
  ✓ Consistent tooling (CI/CD, linting, testing)
  ✓ Easier refactoring across services
  ✓ Simpler dependency management

Monorepo cons:
  ✗ Large repository (slower clone, more storage)
  ✗ Complex CI/CD (must detect changed services)
  ✗ Team conflicts (merging unrelated services)
  ✗ Access control complexity (can't hide service code)

Polyrepo (many repos):
  ✓ Small, fast clones
  ✓ Independent deployment cadence
  ✓ Team autonomy (own repo = own rules)
  ✓ Easier access control (per-repo permissions)

Polyrepo cons:
  ✗ Cross-service updates require multiple PRs
  ✗ Dependency hell (version mismatches)
  ✗ Harder refactoring (changes across repos)
  ✗ Integration testing complex
```

**Monorepo Organization Patterns**

```
Pattern 1: Google-style (Services at top level)

monorepo/
  ├── api-service/
  │   ├── src/
  │   ├── tests/
  │   ├── Dockerfile
  │   └── k8s-deployment.yaml
  ├── worker-service/
  ├── queue-service/
  ├── shared/
  │   ├── auth/
  │   ├── logging/
  │   └── metrics/
  ├── infra/
  │   ├── kubernetes/
  │   └── terraform/
  └── BUILD (Bazel/Gradle config)

Pattern 2: Workspaces (npm monorepos)

monorepo/
  ├── package.json
  └── packages/
      ├── @company/api/
      ├── @company/worker/
      ├── @company/shared-auth/
      └── @company/shared-logging/

Pattern 3: Directory layout (flat structure)

monorepo/
  ├── services/
  │   ├── api/
  │   ├── worker/
  │   └── queue/
  ├── libraries/
  │   ├── auth/
  │   └── logging/
  └── infrastructure/
      ├── docker/
      └── kubernetes/
```

**Monorepo CI/CD: Selective Building**

```bash
#!/bin/bash
# ci.sh: Build only changed services (not entire repo)

# Get list of changed files in this PR
CHANGED_FILES=$(git diff --name-only origin/main...HEAD)

# Determine which services changed
SERVICES_TO_BUILD=()

if echo "$CHANGED_FILES" | grep -q "^services/api/"; then
    SERVICES_TO_BUILD+=("api")
fi

if echo "$CHANGED_FILES" | grep -q "^services/worker/"; then
    SERVICES_TO_BUILD+=("worker")
fi

if echo "$CHANGED_FILES" | grep -q "^services/queue/"; then
    SERVICES_TO_BUILD+=("queue")
fi

# Also rebuild dependent services
if echo "$CHANGED_FILES" | grep -q "^shared/"; then
    SERVICES_TO_BUILD=("api" "worker" "queue")  # All depend on shared
fi

# Build only affected services
for service in "${SERVICES_TO_BUILD[@]}"; do
    echo "Building $service..."
    docker build -t "company/$service:${GIT_SHA}" "./services/$service"
done

echo "Built services: ${SERVICES_TO_BUILD[*]}"
```

### 6.4 Subtree Merge & Mixed Approaches {#subtree-merge-and-mixed-approaches}

**Subtree Merge: Extract History**

```
Use case: Have 2 separate repos; want to merge into single monorepo
          preserving full commit history of both

Scenario:
  - repo-api: 2000 commits
  - repo-worker: 1500 commits
  - Want: monorepo/ with services/api and services/worker

Solution: Subtree merge

$ cd monorepo
$ git remote add api ../repo-api.git
$ git fetch api

$ git subtree add --prefix services/api api/main

Result:
  - All 2000 commits from repo-api preserved
  - Located under services/api/ path
  - Accessible via normal git log: git log services/api/
  - Can continue history: updates to services/api/ appear as new commits
```

**Hybrid Approach: Monorepo with Shared Submodules**

```
Structure (Best of both worlds):

monorepo/
  ├── services/
  │   ├── api/          (versioned here, can deploy independently)
  │   ├── worker/
  │   └── queue/
  ├── vendor/
  │   ├── logging → (git submodule to external repo)
  │   ├── monitoring → (git submodule)
  │   └── auth → (git submodule)
  └── infra/

Advantages:
  ✓ Services atomic (all in one repo)
  ✓ Shared libraries independently versioned (external repos)
  ✓ Shared libraries updated cross-service in coordinated manner
  ✓ Teams can focus on library development (separate repo)

Deployment flow:
  1. Update vendor/logging to v2.3.0 (git submodule update)
  2. All services in monorepo now using v2.3.0
  3. Single commit: "chore: update dependencies"
  4. Deploy monorepo → all services get new logging version
```

---

## 7. Git Hooks {#git-hooks}

### 7.1 Hook Architecture & Types {#hook-architecture-and-types}

**Hook Lifecycle**

```
Local Development Flow:

Developer makes changes
    ↓
User runs: git commit
    ↓
Git executes: pre-commit hook
    ├─ Lint files
    ├─ Format code
    ├─ Run unit tests
    └─ If fail → abort commit; show errors
    ↓
(if pre-commit passed)
    ↓
Git commits changes to local .git
    ↓
Git executes: post-commit hook (usually very quiet)
    │  ├─ Log the commit
    │  └─ Trigger sync to backup
    ↓
User runs: git push
    ↓
Git executes: pre-push hook
    ├─ Verify branch protection rules
    ├─ Check commit signatures
    └─ Ensure branch naming conventions
    ↓
(if pre-push passed)
    ↓
Git pushes to remote
    ↓
Server executes: pre-receive hook (on server)
    ├─ Final validation before accepting
    └─ Could reject push (no direct commits to main)
    ↓
Server executes: post-receive hook (on server)
    ├─ Trigger CI/CD pipeline
    └─ Send notifications
```

**Hook Types & Default Locations**

```
Location: .git/hooks/

Local Hooks (run on developer machine):

pre-commit          Run before commit created
prepare-commit-msg  Run before commit message editor opens
commit-msg          Run after user enters message (validate message)
post-commit         Run after commit created (usually quiet)
pre-rebase          Run before rebase operation
post-rebase         Run after rebase completes
pre-push            Run before push to remote (last local check)
post-push           Run after push succeeds

Server-Side Hooks (run on Git server):

pre-receive         First check; called once per push
update              Called once per ref being pushed
post-receive        Called once after all refs accepted

Note: Server hooks are in: bare-repo/hooks/ or managed by Git hosting platform
```

**Hook Best Practices**

```bash
# Hook should be:
# 1. Idempotent (can run twice safely)
# 2. Fast (blocking developer can cause frustration)
# 3. Informative (clear error messages)
# 4. Bypassable for emergencies (git commit --no-verify)

#!/bin/bash
# .git/hooks/pre-commit (make executable: chmod +x)

set -e  # Exit on first error

echo "Running pre-commit checks..."

# Check 1: No debug statements
if git diff --cached | grep -q "console.log\|print(\|debugger"; then
    echo "❌ ERROR: Debug statements found"
    echo "   Remove console.log, print(), debugger statements"
    exit 1
fi

# Check 2: No large files
for file in $(git diff --cached --name-only); do
    SIZE=$(git cat-file -s ":$file" 2>/dev/null || echo 0)
    if [ "$SIZE" -gt 10485760 ]; then  # 10MB
        echo "❌ ERROR: File too large: $file ($SIZE bytes)"
        echo "   Use Git LFS for large files"
        exit 1
    fi
done

# Check 3: Formatting (quick check)
echo "Checking code formatting..."
make lint  # Should be <5 seconds for performance

echo "✓ Pre-commit checks passed"
exit 0
```

### 7.2 Client-Side Hooks for Quality {#client-side-hooks-for-quality}

**Hook Installation & Sharing**

```bash
#!/bin/bash
# install_hooks.sh: Deploy shared hooks to all developers

REPOSITORY_HOOKS_DIR="scripts/git-hooks"
DEVELOPER_HOOKS_DIR=".git/hooks"

for hook_file in "$REPOSITORY_HOOKS_DIR"/*; do
    hook_name=$(basename "$hook_file")
    
    cp "$hook_file" "$DEVELOPER_HOOKS_DIR/$hook_name"
    chmod +x "$DEVELOPER_HOOKS_DIR/$hook_name"
    
    echo "Installed hook: $hook_name"
done

# Also update git config to use hooks
git config core.hooksPath scripts/git-hooks
```

**Common Quality Hooks**

```bash
#!/bin/bash
# scripts/git-hooks/pre-commit (shared hook)

set -e
FAILED=0

echo "Running pre-commit quality checks..."

# Style Check
if ! make lint --silent; then
    echo "❌ Style check failed"
    FAILED=1
fi

# Unit Tests
if ! make test --silent; then
    echo "❌ Unit tests failed"
    FAILED=1
fi

# Type Checking (for Go/Python/TypeScript)
if ! make type-check --silent 2>/dev/null; then
    echo "⚠️  Type check failed (non-blocking)"
fi

if [ $FAILED -eq 1 ]; then
    echo ""
    echo "Fix errors above before committing."
    echo "To bypass: git commit --no-verify"
    exit 1
fi

echo "✓ All checks passed"
```

### 7.3 Server-Side Hooks for Policy {#server-side-hooks-for-policy}

**Server-Side Hook Enforcement**

```bash
#!/bin/bash
# bare-repo/hooks/pre-receive (on Git server)

set -e

echo "Server-side validation..."

# Read incoming refs being pushed
while read oldrev newrev refname; do
    # Check 1: Enforce branch protection
    if [[ $refname == "refs/heads/main" ]]; then
        if [ "$(git log --oneline $oldrev..$newrev | wc -l)" -gt 5 ]; then
            echo "❌ ERROR: Can't push >5 commits to main"
            echo "   Use feature branch + pull request"
            exit 1
        fi
    fi
    
    # Check 2: Require signed commits
    for commit in $(git rev-list $oldrev..$newrev); do
        if ! git verify-commit "$commit" 2>/dev/null; then
            echo "❌ ERROR: Unsigned commit: $commit"
            echo "   Configure GPG signing: git config user.signingkey"
            echo "   Commit with: git commit -S"
            exit 1
        fi
    done
done

echo "✓ Server validation passed"
exit 0
```

### 7.4 Hook Automation Framework {#hook-automation-framework}

**Husky Framework (JavaScript/Node Projects)**

```json
{
  "devDependencies": {
    "husky": "^8.0.0",
    "lint-staged": "^13.0.0"
  },
  "scripts": {
    "prepare": "husky install"
  }
}

// .husky/pre-commit (installed by Husky)
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

npx lint-staged
npx jest --bail --findRelatedTests  // Run tests for changed files
```

**Custom Hook Framework (Bash/General)**

```bash
#!/bin/bash
# scripts/hooks-framework.sh: Reusable hook system

HOOKS_DIR="hooks"

# Define hooks registry
declare -A HOOKS_REGISTRY=(
    ["pre-commit"]="check_formatting check_tests check_security"
    ["pre-push"]="check_branch_protection check_signed_commits"
    ["commit-msg"]="validate_commit_message"
)

# Execute registered hooks
execute_hook_chain() {
    local hook_name=$1
    
    if [ -z "${HOOKS_REGISTRY[$hook_name]}" ]; then
        return 0  # No hooks registered
    fi
    
    for check in ${HOOKS_REGISTRY[$hook_name]}; do
        echo "Running: $check"
        if ! "./$HOOKS_DIR/$check.sh"; then
            echo "❌ Hook failed: $check"
            return 1
        fi
    done
    
    return 0
}

execute_hook_chain "$@"
```

---

## 8. Collaboration Models {#collaboration-models}

### 8.1 Workflow Model Taxonomy {#workflow-model-taxonomy}

**Workflow Decision Matrix**

```
Question: What's your team structure and deployment requirements?

Small teams (3-5):
  ✓ Linear workflow: Single main branch; all features go there
  ✗ Too primitive for coordination

Medium teams (10-30):
  ✓ GitHub Flow: main + feature branches; short-lived PRs
  ✓ Trunk-based: main is always deployable; release branches for stable versions

Large teams (50+):
  ✓ Gitflow: Separate develop/main; release planning; hotfixes coordinated
  ✓ Monorepo + service selection: Multiple services, deploy independently
  ✗ Long-lived branches cause merge hell

Regulated industries (Finance, Healthcare):
  ✓ Strict branch protection + code review requirements
  ✓ Signed commits mandatory
  ✗ Simple workflows insufficient
```

**Workflow Comparison Table**

| Aspect | GitHub Flow | Gitflow | Trunk-Based | Centralized |
|--------|-------------|---------|-------------|-------------|
| **Main Branch** | Always production-ready | Release gate | Always deployable | Single source of truth |
| **Feature Branches** | Short-lived (days) | Long-lived (weeks) | Minimal/daily | N/A |
| **Deployment** | Continuous after merge | Scheduled from release/ | Periodic from main | On-demand from main |
| **Release Management** | Tags on main | release/* branches | Semantic versioning tags | Manual versioning |
| **Team Size** | Small-Medium (< 50) | Medium-Large (50-200) | Small-Large (any) | Any (higher risk) |
| **Complexity** | Simple | Complex | Simple | Low (informal) |

### 8.2 Gitflow & Release Workflows {#gitflow-and-release-workflows}

**Gitflow Architecture**

```
                        release/v2.1.0 ──→ v2.1.0 (tag)
                               ↑
                              /
    develop ─────────────────┴──→ merge back
       ↑           ↑                  ↓
       └─feature/X─┤      hotfix/v2.0.1 (emergency fix)
       └─feature/Y─┤           ↑ (merge to main)
       └─feature/Z─┘           ↓
                       main ────→ v2.0.1 (tag)
                               ← merge back to develop

Branch purposes:
  main:         Production releases (tags only)
  develop:      Integration branch for features
  feature/*:    Individual features (developer branches)
  release/*:    Release preparation (version bump, final testing)
  hotfix/*:     Emergency production fixes (branches from main)
```

**Gitflow Workflow Script**

```bash
#!/bin/bash
# Start feature development

git checkout develop
git pull origin develop

# Create feature branch (naming convention enforced)
FEATURE_NAME=$1
if [[ ! $FEATURE_NAME =~ ^[a-z0-9_-]+$ ]]; then
    echo "❌ Invalid feature name: $FEATURE_NAME"
    echo "   Use lowercase letters, numbers, hyphens, underscores"
    exit 1
fi

git checkout -b "feature/$FEATURE_NAME"
git push -u origin "feature/$FEATURE_NAME"

echo "✓ Feature branch created: feature/$FEATURE_NAME"
```

**Release Preparation (Gitflow)**

```bash
#!/bin/bash
# prepare_release.sh: Create release branch from develop

VERSION=$1

if [ -z "$VERSION" ]; then
    echo "Usage: ./prepare_release.sh v2.1.0"
    exit 1
fi

git checkout develop
git pull origin develop

# Create release branch
git checkout -b "release/$VERSION"

# Update version in files
sed -i "s/version: .*/version: $VERSION/" package.json
sed -i "s/VERSION=.*/VERSION=$VERSION/" Makefile

git commit -am "chore: bump version to $VERSION"
git push -u origin "release/$VERSION"

echo "✓ Release branch created: release/$VERSION"
echo "   Next: Create pull request to main for code review"
```

### 8.3 GitHub Flow & Trunk-Based Development {#github-flow-and-trunk-based}

**GitHub Flow (Simple, Continuous Deployment)**

```
main (always deployable, tagged releases)
  ↑
  └── feature/feature-name (short-lived, 1-3 days)
      ├── Develop locally
      ├── Push commits
      ├── Open pull request
      ├── Code review + CI/CD
      └─→ Merge to main → Deploy immediately

Key characteristics:
  - One long-lived branch (main)
  - Feature branches are temporary (cleanup after merge)
  - Continuous deployment (every merge to main goes to production)
  - Requires strong CI/CD + monitoring
```

**Trunk-Based Development (Google/Facebook Pattern)**

```
Pattern 1: Direct commits to main
  Developers commit directly to main (very disciplined teams)
  Frequent releases (hourly)
  Risk: High (needs excellent tests + monitoring)

Pattern 2: Short-lived feature branches + trunk
  Feature branches (hours to 1 day max)
  Merge to main frequently
  Main always deployable
  Release whenever ready (no release branches)

Deployment flow:
  main (commit abc) →  Build & test → Deploy v2.5.0
  main (commit def) →  Build & test → Deploy v2.5.1
  main (commit ghi) →  Build & test → Deploy v2.5.2
  
  No release/* branches; no versioning complexity
```

**Trunk-Based Development CI/CD**

```bash
#!/bin/bash
# .github/workflows/trunk-based-deploy.yml (GitHub Actions)

on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Run tests
        run: make test
        
      - name: Build containers
        run: make docker-build
        
      - name: Push containers
        run: docker push company/api:${{ github.sha }}
        
      - name: Deploy to staging
        run: kubectl set image deployment/api api=company/api:${{ github.sha }} -n staging
        
      - name: Run smoke tests
        run: ./tests/smoke.sh https://staging.company.com
        
      - name: Deploy to production
        run: ./scripts/deploy-production.sh --image company/api:${{ github.sha }}
        
      - name: Tag release
        run: git tag -a v$(date +%Y.%m.%d-%H%M%S) -m "Auto-release"
```

### 8.4 Choosing Workflows for Organization {#choosing-workflows-for-organization}

**Decision Framework**

```
START HERE:

1. How many services?
   │
   ├─ Single service
   │  └─ Go to Q2
   │
   └─ Multiple services (Monorepo or Polyrepo)
      └─ Go to Q3

2. (Single service) How many developers?
   │
   ├─ <10: GitHub Flow
   │
   ├─ 10-50: GitHub Flow or Trunk-Based
   │
   └─ 50+: Gitflow or Trunk-Based + service-level controls

3. (Multiple services) What's your deployment frequency?
   │
   ├─ Weekly or slower: Gitflow (coordinated releases)
   │
   ├─ Multiple times per week: Trunk-Based (independent services)
   │
   └─ Continuous (multiple/day): Trunk-Based (required)

4. Compliance requirements?
   │
   ├─ None: Choose above
   │
   └─ Yes (regulated industry):
      ├─ Require: Signed commits
      ├─ Require: Code review approval
      ├─ Require: Branch protection (can't force-push)
      └─ Add: Audit trail integration
```

---

## 9. Pull Requests & Code Reviews {#pull-requests--code-reviews}

### 9.1 Pull Request Mechanics & Patterns {#pull-request-mechanics}

**Pull Request Lifecycle**

```
Developer creates feature branch:
  $ git checkout -b feature/xyz

Makes commits:
  $ git add src/component.go
  $ git commit -m "feat: add new component"

Pushes to remote:
  $ git push -u origin feature/xyz

Opens pull request (on GitHub/GitLab):
  - Compares feature/xyz against main
  - Shows diff of all commits
  - Enables discussion

CI/CD automatically triggered:
  - Run tests
  - Lint code
  - Build containers
  - Deploy to staging

Code review begins:
  - Reviewers examine changes
  - Request modifications
  - Developer pushes new commits

Approval + passing CI:
  - Merge button enabled
  - Developer merges (or auto-merge enabled)
  - Branch deleted
  - Webhook triggers production deploy

Revert if necessary:
  - git revert <merge-commit-sha>
  - New commit undoes PR entirely
```

**Pull Request Naming Convention**

```
Good PR titles (searchable, informative):

✓ feat: add OAuth2 support to API
✓ fix: handle race condition in cache eviction
✓ chore: update dependencies (Node 18.2 → 20 LTS)
✓ perf: optimize database queries for user list endpoint
✓ docs: add deployment procedures to README

Bad PR titles (vague, unsearchable):

✗ WIP: stuff
✗ fix things
✗ update code
✗ merge my changes
```

**PR Description Template**

```markdown
## Description
Brief summary of changes.

## Related Issues
Fixes #123
Related to: #456

## Changes Made
- [ ] Change 1
- [ ] Change 2
- [ ] Breaking change: removed deprecated API endpoint

## Testing
- [ ] Unit tests added
- [ ] Tested in staging environment
- [ ] Manual test steps:
  1. Start service: `docker-compose up`
  2. Call endpoint: `curl http://localhost:8080/api/v1/users`
  3. Verify response includes new 'email_verified' field

## Performance Impact
- [ ] No performance impact
- [ ] Improves performance (see benchmark results)
- [ ] Degrades performance: acceptable because <reason>

Benchmarks:
```
Before: p99 latency 150ms
After:  p99 latency 45ms
```

## Deployment
- [ ] No database migrations
- [ ] Requires database migration (see scripts/migrate_v2.sql)
- [ ] Requires config changes (see CONFIG.md)
```

### 9.2 Code Review Best Practices {#code-review-best-practices}

**Review Checklist for DevOps Teams**

```bash
#!/bin/bash
# Code Review Checklist (automated where possible)

echo "Code Review Validation Checklist"
echo "================================"

# 1. Commit history quality
echo -n "✓ Commit messages follow convention? "
if git log --format='%B' $base..$head | grep -qE '^(feat|fix|chore|perf|docs):'; then
    echo "YES"
else
    echo "NO - Review commit messages"
fi

# 2. Change size
STATS=$(git diff --stat $base..$head | tail -1)
FILES=$(echo "$STATS" | awk '{print $1}')
CHANGES=$(echo "$STATS" | awk '{print $4+$6}')

echo "  Files changed: $FILES"
echo "  Total changes: $CHANGES lines"

if [ "$FILES" -gt 30 ] || [ "$CHANGES" -gt 1000 ]; then
    echo "  ⚠️  Large diff - Request split into smaller PRs"
fi

# 3. Test coverage
echo -n "✓ Tests added/modified? "
if git diff $base..$head | grep -q '+.*test'; then
    echo "YES"
else
    echo "NO - Ensure tests are included"
fi

# 4. Documentation
echo -n "✓ Documentation updated? "
git diff $base..$head --name-only | grep -q -E '\.md$|docs/|README'
if [ $? -eq 0 ]; then
    echo "YES"
else
    echo "UNCLEAR - Check if docs needed"
fi

# 5. No security issues
echo -n "✓ No hardcoded secrets? "
if git diff $base..$head | grep -qE 'password|api_key|secret|token'; then
    echo "⚠️  CHECK - Review for hardcoded credentials"
else
    echo "YES"
fi
```

**Review Comment Guidelines**

```
❌ BAD REVIEW COMMENTS (unconstructive):

"This is wrong"
"Why did you do it this way?"
"This sucks"

✓ GOOD REVIEW COMMENTS (constructive):

"Consider using `map()` instead of `for` loop for 
 functional pipeline:

    const mapped = data.map(x => x.value)

 This is more idiomatic and easier to parallelize."

"This function has cyclomatic complexity of 8 (target: <5).
 Consider extracting the nested if/switch into separate functions.
 See: https://our-standards.md#function-complexity"

"Performance concern: This query runs N+1 operations 
 (see function X calling Y in a loop).
 Suggest using batch query:
   SELECT * FROM users WHERE id IN (...)"
```

### 9.3 Merge Strategies in Pull Requests {#merge-strategies-in-pull-requests}

**Three Merge Strategies Explained**

```
Repository state:

main:     A ─── B ─── C (current main)
               /
feature/x:    D ─── E (feature branch)

Want to merge feature/x into main?

───────────────────────────────────────────────────

STRATEGY 1: Merge Commit (creates merge commit)

Result:
  A ─── B ─── C ─── M (merge commit)
        └─── D ─── E ─┘

Pros:
  ✓ Full history preserved (can see entire feature branch DAG)
  ✓ Reversible (git revert works easily)
  ✓ Audit trail (merge commit shows feature integration point)

Cons:
  ✗ Complex history graph (hard to read with many PRs)
  ✗ Slower bisect (need to skip merge commits)

History: git log main
  M   Merge branch feature/x
  C   Comment on docs
  B   Add cache layer
  A   Initial commit

───────────────────────────────────────────────────

STRATEGY 2: Squash (combines into single commit)

Result:
  A ─── B ─── C ─── F (squashed commit = D+E combined)

Pros:
  ✓ Clean history (one commit = one feature)
  ✓ Easy bisect (each commit is logical unit)
  ✓ Readable history

Cons:
  ✗ History lost (intermediate steps gone)
  ✗ Harder to trace authorship (squashed commit by merger)
  ✗ Revert shows as single line (poor for debugging)

History: git log main
  F   Add user authentication (squashed)  [Contains D+E]
  C   Comment on docs
  B   Add cache layer
  A   Initial commit

───────────────────────────────────────────────────

STRATEGY 3: Rebase (replays commits on main)

Result:
  A ─── B ─── C ─── D' ─── E' (D and E replayed on C)

Pros:
  ✓ Linear history (easiest to read)
  ✓ Each commit independently valid
  ✓ Bisect optimal

Cons:
  ✗ History rewritten (SHAs change)
  ✗ Can't use on shared branches
  ✗ Confusing if force-pushed publicly

History: git log main
  E'  Implement cache expiration
  D'  Add Redis connection pooling
  C   Comment on docs
  B   Add cache layer
  A   Initial commit
```

**Choosing Merge Strategy**

```
Default recommendation:
  → Use MERGE COMMIT (preserves causality)
  → Exception: Internal features (1-2 commits) → squash

Specific recommendations:

Bug fixes:     Merge commit (shows when bug was fixed)
Features:      Merge commit (shows design decision point)
Chores:        Squash (cleanup, not important history)
Docs:          Squash (multiple small commits unnecessary)

Large refactoring:
  → Rebase (if private branch; easier history)
  → Merge commit (if public branch; shows integration point)
```

**GitHub PR Merge Automation**

```yaml
# .github/workflows/auto-merge.yml

name: Auto-merge approved PRs

on:
  pull_request:
    types: [labeled]

jobs:
  auto-merge:
    if: contains(github.event.pull_request.labels.*.name, 'auto-merge')
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Enable auto merge
        run: |
          gh pr merge --auto --squash "${{ github.event.pull_request.number }}"
        env:
          GH_TOKEN: ${{ github.token }}
```

### 9.4 CI/CD Integration with PRs {#cicd-integration-with-prs}

**Required Status Checks**

```yaml
# .github/workflows/required-checks.yml

on:
  pull_request:
    branches: [main]

jobs:
  tests:
    runs-on: ubuntu-latest
    name: "Test Suite"
    steps:
      - uses: actions/checkout@v3
      - run: make test
      # If this fails, PR can't be merged
      
  lint:
    runs-on: ubuntu-latest
    name: "Code Quality"
    steps:
      - uses: actions/checkout@v3
      - run: make lint
      
  security:
    runs-on: ubuntu-latest
    name: "Security Scanning"
    steps:
      - uses: actions/checkout@v3
      - run: make security-scan
      
  docker-build:
    runs-on: ubuntu-latest
    name: "Build Container"
    steps:
      - uses: actions/checkout@v3
      - run: docker build -t company/api:test .
      # Verify Dockerfile works before merging

# Repository settings (GitHub):
# Settings → Branches → main
#   ✓ Require status checks to pass before merging
#   ✓ Require branches to be up to date before merging
#   ✓ Require code reviews before merging (1 approval)
#   ✓ Dismiss stale pull request approvals when new commits are pushed
```

---

## 10. Large Repository Handling {#large-repository-handling}

### 10.1 Performance Analysis & Optimization {#performance-analysis-and-optimization}

**Diagnosing Repository Bloat**

```bash
#!/bin/bash
# analyze_repo_size.sh

echo "Repository Size Analysis"
echo "========================"

# Total size
TOTAL_SIZE=$(du -sh .git | cut -f1)
echo "Total .git size: $TOTAL_SIZE"

# Object database size
OBJECTS_SIZE=$(du -sh .git/objects | cut -f1)
echo "Objects database: $OBJECTS_SIZE"

# Largest files (loose objects)
echo ""
echo "Largest loose objects:"
find .git/objects -type f -printf '%s %p\n' | sort -rn | head -10 | \
    while read size path; do
        MB=$((size / 1048576))
        if [ $MB -gt 0 ]; then
            echo "  $MB MB: $path"
        fi
    done

# Find large files in history
echo ""
echo "Largest files ever committed:"
git rev-list --all --objects | \
    sed -n '/\//p' | \
    cut -f2 -d' ' | \
    sort -u | \
    xargs git cat-file -p | \
    awk '{print $3" "$4}' | \
    sort -rn | \
    head -20

# Compression statistics
echo ""
echo "Packing efficiency:"
if [ -d ".git/objects/pack" ]; then
    PACKED_SIZE=$(du -sh .git/objects/pack | cut -f1)
    echo "Packed objects: $PACKED_SIZE"
else
    echo "No packed objects (run: git gc --aggressive)"
fi
```

**Optimization Techniques**

```bash
#!/bin/bash
# optimize_repository.sh

echo "Optimizing repository..."

# Step 1: Aggressive garbage collection
echo "1. Compressing objects..."
git gc --aggressive --prune=now

# Step 2: Repack with delta compression
echo "2. Repacking with delta compression..."
git repack -F -d

# Step 3: Commit graph for faster operations
echo "3. Building commit graph (Git 2.18+)..."
git commit-graph write --reachable --changed-paths 2>/dev/null || true

# Step 4: Verify integrity
echo "4. Verifying integrity..."
git fsck --full

echo "✓ Optimization complete"
du -sh .git
```

### 10.2 Git LFS & Object Management {#git-lfs-and-object-management}

**Git LFS Architecture**

```
Standard Git (stores full files):
  
  repository/
    └── models/
        └── model.pkl (50MB)
  
  When cloned:
    git clone → downloads entire 50MB file

Git LFS (stores only pointers):
  
  repository/
    └── models/
        └── model.pkl→ pointer file (1KB)
  
  Pointer content:
    version https://git-lfs.github.com/spec/v1
    oid sha256:abc1234def5678
    size 52428800
  
  When cloned:
    git clone → downloads pointer (1KB)
    git lfs pull → downloads actual file from LFS server (on demand)
```

**Git LFS Setup & Usage**

```bash
#!/bin/bash
# Setup Git LFS for large files

# Install Git LFS
brew install git-lfs          # macOS
# or: apt-get install git-lfs   # Linux

# Initialize LFS in repository
git lfs install                # One-time setup

# Track large file types
git lfs track "*.pkl"          # Python models
git lfs track "*.bin"          # Binary models
git lfs track "*.pth"          # PyTorch models
git lfs track "*.mp4"          # Videos
git lfs track "*.iso"          # Disk images

# Commit tracking configuration
git add .gitattributes
git commit -m "chore: configure Git LFS for large files"

# Now add large files (stored via LFS, not Git)
git add model.pkl
git add video.mp4
git commit -m "feat: add trained model"

# LFS storage location  
git lfs ls-files              # See all LFS-tracked files

# Pull LFS files (on clone, only pointers are downloaded)
git lfs pull                  # Download tracked files locally
```

**LFS Migration: Convert Existing Large Files**

```bash
#!/bin/bash
# migrate_to_lfs.sh: Move existing large files to LFS

# Step 1: Install LFS
git lfs install

# Step 2: Track file type (forward)
git lfs track "*.pkl"

# Step 3: Migrate historical: *This rewrites history*
git lfs migrate import --include "*.pkl" --everything

# Step 4: Verify
git lfs ls-files

# Step 5: Push (uploads both metadata and LFS objects)
git push --all --lfs
```

### 10.3 Shallow & Partial Clones {#shallow-and-partial-clones}

**Clone Strategies Compared**

```
Full Clone:
  $ git clone https://repo.git
  Downloads: ALL commits, ALL branches, ALL tags, ALL objects
  Size: ~1-10 GB for large repos
  Time: 15-60 minutes
  Use: Initial repo setup (one-time)

Shallow Clone:
  $ git clone --depth 1 https://repo.git
  Downloads: 1 commit (latest) + ~100 commits of dependencies
  Size: ~50-100 MB
  Time: 30 seconds
  Limitation: Can't checkout old branches; limitations on rebase
  Use: CI/CD pipelines (don't need history)

Partial Clone:
  $ git clone --filter=blob:none https://repo.git
  Downloads: All commits, trees; no blob contents
  On-demand: Blobs downloaded when accessed (git show, checkout)
  Size: ~100 MB (metadata only)
  Time: 10-30 seconds
  Use: Developer machines (most files never actually accessed)

Sparse Checkout:
  $ git clone --sparse https://repo.git
  Downloads: Only specified directory trees
  size: Subset of repo
  Use: Monorepos (developers work on single service)
```

**Shallow Clone for CI/CD**

```yaml
# .github/workflows/ci.yml

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      # Fast shallow clone for CI
      - uses: actions/checkout@v3
        with:
          fetch-depth: 1  # Equivalent to: git clone --depth 1
          
      - name: Run tests
        run: make test
        
      - name: Build container
        run: docker build -t myapp:${{ github.sha }} .
```

**Sparse Checkout for Monorepo**

```bash
#!/bin/bash
# Clone monorepo but only work on "services/api" directory

git clone --sparse --depth 1 https://repo.git

cd repo

# Only fetch the api service directory
git sparse-checkout set services/api

# Now working tree only contains:
#   services/api/
# (not: services/worker, services/queue, etc.)

# Benefits for developer:
#   - Smaller working directory (faster)
#   - Fewer files to open in editor (~100 vs ~5000)
#   - git status faster
#   - Build tools process fewer files
```

### 10.4 Repository Splitting & Migration {#repository-splitting-and-migration}

**Repository Splitting (Extract Module to Own Repo)**

```bash
#!/bin/bash
# split_repository.sh: Extract module to independent repo

# Scenario: Monorepo has 15 services; extract "shared-auth" to own repo

MONOREPO=/path/to/monorepo
SUBDIR=vendor/shared-auth
NEW_REPO=/path/to/new-repo

# Step 1: Clone source
git clone --no-hardlinks "$MONOREPO" "$NEW_REPO"
cd "$NEW_REPO"

# Step 2: Use filter-repo to keep only the subdir (rewrite history)
git filter-repo --path "$SUBDIR" --path-rename "$SUBDIR:."

# Result:
#   vendor/shared-auth/auth.go  → ./auth.go
#   All commits filtered to only touch this dir
#   History cleaned automatically

# Step 3: Add remote for new repo
git remote set-url origin https://github.com/company/shared-auth.git

# Step 4: Push
git push -u origin main
git push --tags

echo "✓ Repository split complete"
```

**Monorepo Merge (Combine Multiple Repos)**

```bash
#!/bin/bash
# merge_repos_to_monorepo.sh

# Scenario: Merge repo-api, repo-worker into monorepo/services/

MONOREPO=/path/to/monorepo
cd "$MONOREPO"

# Merge repo-api into services/api/
git remote add api ../repo-api.git
git fetch api
git subtree add --prefix services/api api/main

# Merge repo-worker into services/worker/
git remote add worker ../repo-worker.git
git fetch worker
git subtree add --prefix services/worker worker/main

# Commit the merge
git commit -m "feat: merge repo-api and repo-worker into monorepo"

# Important: Both repos' complete histories are preserved!
# Can still: git log services/api/  (shows all API service commits)
```

---

## 11. Hands-on Scenarios {#hands-on-scenarios}

### 11.1 Emergency Production Hotfix Coordination {#emergency-production-hotfix}

**Scenario: Production Database Query Regression**

```bash
#!/bin/bash
# INCIDENT: 2 AM - User service responding in 15s (SLA: 500ms)
# Root cause: Query N+1 problem in user list endpoint

# Step 1: Stash current feature work
$ git stash push -m "INCIDENT-15234: saved feature/async-reporting work"

# Step 2: Create urgent hotfix branch from stable tag
$ git checkout v2.14.0  # Last stable production version
HEAD is now at abc123: Release v2.14.0

$ git checkout -b hotfix/query-regression-v2.14.1

# Step 3: Identify the offending query
$ git blame src/services/user_service.go | grep -A5 "for user := range users"
abc123  john@company.com (2024-03-10)  145: for user := range users {
def456  john@company.com (2024-03-10)  146:     details := db.GetUserDetails(user.ID)  // N+1!

# Step 4: Fix the regression
git log abc123..def456 --oneline  # See what changed

# Edit file:
# Change:    for user := range users { details := db.GetUserDetails(user.ID) }
# To:        details := db.BatchGetUserDetails(userIDs)

# Step 5: Test locally
$ make test  # Unit tests pass
$ make benchmark src/services/user_service.go
  Before: p99 = 15000ms
  After:  p99 = 450ms ✓

# Step 6: Create emergency commit
$ git commit -am "fix: prevent N+1 query in user list endpoint"

# Step 7: Push for code review (expedited)
$ git push origin hotfix/query-regression-v2.14.1

# Step 8: Create pull request (mark as urgent)
# Title: "[URGENT] Fix N+1 query regression - user list endpoint p99 15s→450ms"
# Comment: @oncall @security-team Emergency hotfix for production incident

# Step 9: After approval, merge and deploy
$ git checkout main
$ git merge hotfix/query-regression-v2.14.1 --no-ff
$ git tag v2.14.1
$ git push origin main --tags

# Step 10: Verify deployment metrics
# Check: New queries per request reduced from 500 to 5
# Check: p99 latency back to <500ms
# Check: No new errors in monitoring

# Step 11: Post-incident, return to feature work
$ git checkout feature/async-reporting
$ git stash pop  # Restore stashed work
```

### 11.2 Multi-Team Submodule Synchronization {#multi-team-submodule-sync}

**Scenario: 3 Teams, 5 Shared Libraries Need Update**

```bash
#!/bin/bash
# Coordinate update of shared-auth v1.5 → v2.0 (breaking change)

# Step 1: Planning meeting
echo "Shared-auth v2.0 Breaking Changes:"
echo "  - SessionToken.validate() → SessionToken.validate(ContextRaw)"
echo "  - Config key: auth_provider → auth_provider_v2"
echo "  - All services must update simultaneously"

# Step 2: Queue releases
SERVICES=(
    "microservice-api"
    "microservice-worker"
    "microservice-queue"
)

for service in "${SERVICES[@]}"; do
    cd "$service"
    
    # Update submodule to new version
    cd vendor/shared-auth
    git fetch origin
    git checkout v2.0.0
    cd ../..
    
    # Update code for breaking changes
    sed -i 's/auth_provider/auth_provider_v2/g' src/config.go
    sed -i 's/\.validate()/\.validate(ctx)/g' src/middleware.go
    
    # Commit
    git commit -am "feat: upgrade shared-auth v1.5→v2.0 (breaking change)"
    git push origin feature/shared-auth-v2
    
    # Create PR
    hub pull-request -m "chore: upgrade shared-auth v2.0"
done

# Step 3: Synchronize merges (all at once)
echo "Waiting for all team PRs to be approved..."

for service in "${SERVICES[@]}"; do
    cd "$service"
    git checkout main
    git pull
    git merge feature/shared-auth-v2
done

echo "✓ All services updated to shared-auth v2.0 simultaneously"
```

### 11.3 Repository Splitting & History Rewriting {#repository-splitting-and-rewriting}

**Scenario: Large Company Acquiring Startup, Need to Merge Codebases**

```bash
#!/bin/bash
# Merge startup's payment-service repo into company monorepo

STARTUP_REPO="https://github.com/startup/payment-service.git"
COMPANY_MONOREPO="/path/to/company/monorepo"

cd "$COMPANY_MONOREPO"

# Clone startup repo as temporary
git clone "$STARTUP_REPO" /tmp/payment-service-temp
cd /tmp/payment-service-temp

# Preserve all history but relocate files
git filter-repo --path-rename ":services/payment-service"

# Back to monorepo
cd "$COMPANY_MONOREPO"
git remote add payment-service /tmp/payment-service-temp
git fetch payment-service

# Merge with full history preserved
git merge payment-service/main --allow-unrelated-histories -m "feat: acquire payment-service from startup acquisition"

# Commit should show:
#  - All files now in services/payment-service/
#  - All startup commits preserved in history
#  - Traceable lineage

# Verify
git log --all --decorate --oneline | head -30  # See startup commits
git log -p -- services/payment-service | head -50  # See old startup commits under new path
```

### 11.4 Migrating to Monorepo Architecture {#migrating-to-monorepo}

**Scenario: Convert Polyrepo (10 separate repos) to Monorepo**

```bash
#!/bin/bash
# Execute monorepo migration over 1 week

# Step 1: Plan and communicate
echo "Monorepo Migration Plan"
echo "Day 1: Merge repo-api into monorepo"
echo "Day 2: Merge repo-worker into monorepo"
echo "Day 3: Merge repo-queue, repo-logger into monorepo"
echo "Day 4-5: Rebuild CI/CD, local tooling"
echo "Day 6: Test full monorepo workflow"
echo "Day 7: Switch production"

# Step 2: Create monorepo scaffold
mkdir monorepo
cd monorepo
git init
echo "# Cloud Company Monorepo" > README.md
git add README.md
git commit -m "chore: initialize monorepo with structure

services/
vendor/
infra/
tools/
docs/
"

# Step 3: Migrate each repo (preserving history)
for repo in api worker queue logger; do
    git remote add $repo https://github.com/company/repo-$repo.git
    git fetch $repo
    git subtree add --prefix services/$repo $repo/main \
        --message="feat: migrate repo-$repo into monorepo"
done

# Step 4: Rebuild CI/CD pipeline
cat > .github/workflows/monorepo-ci.yml <<'EOF'
on: [push, pull_request]
jobs:
  detect-changes:
    runs-on: ubuntu-latest
    outputs:
      services: ${{ steps.changed.outputs.services }}
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      - id: changed
        run: |
          git diff --name-only ${{ github.event.pull_request.base.sha }} \
            | grep '^services/' \
            | cut -d'/' -f2 \
            | sort -u \
            | jq -R -s '@json' > /tmp/services.json
          echo "services=$(cat /tmp/services.json)" >> $GITHUB_OUTPUT

  build:
    needs: detect-changes
    runs-on: ubuntu-latest
    strategy:
      matrix:
        service: ${{ fromJson(needs.detect-changes.outputs.services) }}
    steps:
      - uses: actions/checkout@v3
      - run: cd services/${{ matrix.service }} && make test
      - run: cd services/${{ matrix.service }} && docker build .
EOF

git add .github/workflows/monorepo-ci.yml
git commit -m "chore: add monorepo CI/CD pipeline with selective building"

# Step 5: Update developer tooling
cat > tools/dev-setup.sh <<'EOF'
#!/bin/bash
# Local development setup

# Clone monorepo with sparse checkout
git clone --sparse https://github.com/company/monorepo.git
cd monorepo

# Developer only clones their service
SERVICE=$1
git sparse-checkout set services/$SERVICE vendor infra

# Setup: Node, Python, Docker (per service)
cd services/$SERVICE
make setup

echo "✓ Development environment ready for services/$SERVICE"
EOF

chmod +x tools/dev-setup.sh

# Step 6: Merge and switch production
git push origin main
# Deploy monorepo build to staging → smoke tests → production

echo "✓ Monorepo migration complete"
```

---

## 12. Interview Questions {#interview-questions}

### 12.1 Scenario-Based Questions {#scenario-based-questions}

**Question 1: "We have 200 engineers and main branch is constantly failing. Our releases are unpredictable."**

Expected Answer: "This sounds like you're using a long-lived feature branch model (Gitflow) with many concurrent features. Problem: large integration delays, merge conflicts, delayed feedback.

Solution: Migrate to trunk-based development:
- Keep main branch as single source of truth (always deployable)
- Feature branches <1 day old (frequent rebases to main)
- Continuous deployment (main → staging → prod)
- Earlier feedback reduces surprise breakages

Implementation:
1. Invest in test suite (must be fast: <10 min full suite)
2. Enable feature flags (deploy incomplete features safely)
3. Strengthen monitoring (catch issues immediately)
4. Update CI/CD (automated fast feedback loop)

Timeline: 4-6 weeks to stabilize; ongoing culture shift"

**Question 2: "After a developer left, we found critical code only they modified, scattered across the monorepo in 50 files. We're stressed about bus factor."**

Expected Answer: "Bus factor = knowledge concentration risk. Solution:

Immediate actions:
1. Use git blame to identify all files they touched
2. Schedule code review sessions (team learns knowledge)
3. Extract high-risk modules into shared libraries
4. Document why they chose that architecture

Preventive measures:
1. Enforce code review (no single author on critical paths)
2. Pair programming on complex features
3. Commit message standards (including 'why' decisions)
4. Architecture documentation (not just code)

Tools:
- git log --author to find their commits
- git show to review architectural decisions
- Commit message template to ensure decision documentation"

**Question 3: "Hotfix needed at 2 AM but developer's machine has uncommitted work they're worried about losing. How do we handle this?"**

Expected Answer: "This is exactly what stash is for:

Immediate:
1. git stash push -m 'saved-for-recovery-2am'
2. Switch to hotfix branch
3. Emergency fix + deploy
4. Return to feature work: git stash pop

Why this works:
- Stash preserves uncommitted work safely
- Reflog retains stash for 30 days if needed
- No force-push; clean integration

Prevention:
- Educate team on stash usage
- Extend reflog retention: git config gc.reflogExpire '6 months'
- Regular drills (simulate 2 AM scenario)
- Document procedure in runbook"

### 12.2 Architecture & Design Questions {#architecture-design-questions}

**Question 1: "Monorepo vs. Polyrepo: Which should we choose?"**

Expected Answer: "Depends on:

Company structure (tight coupling → monorepo):
- Single team = monorepo
- Multiple autonomous teams = polyrepo options

Deployment synchronization:
- Changes affect many services = monorepo (atomic commits)
- Services deploying independently = polyrepo

Shared library frequency:
- Frequent updates = monorepo (catch breakages immediately)
- Stable APIs = polyrepo (independent versions)

Scale:
- <5 services = monorepo simple
- 20+ services = tool support required (Bazel, Lerna)
- 100+ services = polyrepo (scalability ceiling)

My recommendation:
- Default: Start monorepo (simplest coordination)
- Migrate to polyrepo when:
  - Build times >30 min (split services)
  - Trust conflicts (teams can't coordinate)
  - Deployment cadence diverges (independent versioning needed)

For mixed approach:
- Monorepo for tightly coupled services
- Submodules for shared libraries (independent versioning)
- Enables best of both worlds"

**Question 2: "How do you design a Git workflow that scales from 5 to 500 engineers?"**

Expected Answer: "Progression:

5 developers: GitHub Flow
- One main branch
- Feature branches (1-3 days)
- Simple workflow

20 developers: Add service CI/CD boundaries
- Still GitHub Flow mechanically
- But: Services have own test gates
- Prevent service A breakage from blocking service B deploys

100 developers: Trunk-based + feature flags
- Main always deployable (faster feedback)
- Feature flags prevent incomplete features
- Service CI/CD gates remain

300+ developers: Monorepo + selective building
- Avoid rebuilding entire codebase on every commit
- CI/CD detects changed services
- Deploy only affected services

Technical implementation:
- Phase 1 (0-50): GitHub Flow + GitHub Actions
- Phase 2 (50-150): Monorepo prep + Bazel/Gradle
- Phase 3 (150+): Monorepo complete + selective CI/CD

Cultural aspects:
- Emphasize: shared ownership (code review culture)
- Reduce: silos (cross-team collaboration)
- Enable: fast feedback (visibility into failures)"

### 12.3 Troubleshooting & Recovery Questions {#troubleshooting-recovery-questions}

**Question 1: "Repository is corrupted (fsck fails). How do we recover?"**

Expected Answer: "Diagnosis first:

$ git fsck --full
error: loose object is corrupt
error: object database corrupted

Recovery steps:

Option 1: Local-only corruption (objects.db corrupted but parent repo is healthy)
$ git remote -v  # Verify you have remote
$ git clone --mirror <remote> /tmp/mirror
$ rm -rf .git
$ git clone /tmp/mirror .
$ git reflog expire --expire=now --all
$ git gc --aggressive

Option 2: Both local and remote corrupted
$ git clone --bare <remote> /tmp/backup.git
$ cd /tmp/backup.git
$ git fsck --full
$ git gc --aggressive --prune=now
$ cd -
$ rm -rf .git
$ git clone file:///tmp/backup.git .

Option 3: Complete disaster (no usable backup)
$ git reflog  # Last resort: check if dangling commits exist
$ git fsck --unreachable  # Find orphaned objects
$ git show <found-sha>  # Manually recover

Prevention:
- Mirror repositories (multiple geographic sites)
- Automated backups (weekly)
- Test recovery procedures (quarterly)
- Monitor repository health (automated fsck.sh)"

**Question 2: "Accidentally rebased and force-pushed to main. Now 50 colleagues are confused. How do we recover?"**

Expected Answer: "Critical: Don't panic. Commits are NOT lost (in reflog).

Immediate (before colleagues re-clone):
1. Check reflog: git reflog
   abc def HEAD@{0}: reset: hard
   ghi jkl HEAD@{1}: rebase (abort): returning to refs/heads/main
   mno pqr HEAD@{2}: rebase: commit message

2. Identify pre-rebase state: HEAD@{2} or similar

3. Restore: git reset --hard HEAD@{2}

4. Force-push recovering: git push origin main --force-with-lease

Notifying colleagues:
- Announce: 'Main was accidentally rebased; now fixed'
- Instruction: git pull --rebase origin main (handles merge conflicts)

Post-incident:
1. Review: Who has force-push permission? Too many.
2. Protect: Require PR for main (no direct force-push)
3. Educate: Rebase only on feature branches, never main
4. Tool: Pre-push hook prevents force-push to main"

---

## 13. Expanded Hands-on Scenarios

### 13.1 Scenario: Multi-Datacenter Deployment Coordination with Submodule Dependencies

**Problem Statement**

A financial technology company with 3 regional datacenters deploys services distributed across regions. They have:
- Central payment-service (shared across all regions)
- Regional API services (US-East, EU, APAC)
- Compliance requirements: All regional services must use identical payment-service version

Current pain: Regional teams independently update payment-service dependency, causing version drift. EU region running v1.8, US running v1.9, APAC running v1.7. Reconciliation audit flagged compliance risk.

**Architecture Context**

```
GitHub Monorepo:
  ├── services/payment-service/    (independent Git commits; tag-based versioning)
  ├── services/api-us-east/        (depends on payment-service)
  ├── services/api-eu/             (depends on payment-service)
  ├── services/api-apac/           (depends on payment-service)
  └── infra/deployment/            (orchestrates regional deploys)

Current broken state:
  api-us-east → vendor/payment-service@v1.9 ← LATEST
  api-eu      → vendor/payment-service@v1.8
  api-apac    → vendor/payment-service@v1.7

Deployment pipeline:
  GitHub PR merge → CI/CD runs tests → Deploy to region
  Problem: No synchronization between regions
```

**Step-by-Step Resolution**

**Step 1: Identify Version Drift**

```bash
#!/bin/bash
# audit_submodule_versions.sh

echo "Auditing payment-service versions across regions..."

for region in us-east eu apac; do
    SERVICE_DIR="services/api-$region"
    PAYMENT_REF=$(git -C "$SERVICE_DIR" submodule status vendor/payment-service | awk '{print $1}')
    PAYMENT_TAG=$(git describe --tags "$PAYMENT_REF" 2>/dev/null || echo "unknown")
    
    echo "$region: payment-service@${PAYMENT_TAG} (commit: ${PAYMENT_REF:0:8})"
done

# Output:
# us-east: payment-service@v1.9 (commit: abc12345)
# eu:      payment-service@v1.8 (commit: def67890)
# apac:    payment-service@v1.7 (commit: ghi13579)

# Action: All should be at v1.9
```

**Step 2: Establish Compliance Policy**

```bash
#!/bin/bash
# Create policy: "All regions must use identical payment-service version"

# Add pre-merge hook to enforce this:

cat > .github/workflows/enforce-payment-submodule.yml <<'EOF'
name: Enforce Payment Service Version Consistency

on: [pull_request]

jobs:
  check-consistency:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Get payment-service versions per region
        run: |
          VERSIONS="us_east:$(git config -f .gitmodules submodule.services/api-us-east/vendor/payment-service.url | cut -d'@' -f2)"
          VERSIONS="$VERSIONS eu:$(git config -f .gitmodules submodule.services/api-eu/vendor/payment-service.url | cut -d'@' -f2)"
          VERSIONS="$VERSIONS apac:$(git config -f .gitmodules submodule.services/api-apac/vendor/payment-service.url | cut -d'@' -f2)"
          
          echo "$VERSIONS"
          
          # Extract unique versions
          UNIQUE=$(echo "$VERSIONS" | cut -d':' -f2 | sort -u | wc -l)
          
          if [ "$UNIQUE" -gt 1 ]; then
            echo "❌ ERROR: Regional services have mismatched payment-service versions"
            echo "   All regions MUST use same version for compliance"
            exit 1
          fi
          
          echo "✓ All regions using same payment-service version"
EOF

git add .github/workflows/enforce-payment-submodule.yml
git commit -m "chore: enforce payment-service version consistency across regions"
```

**Step 3: Coordinate Synchronized Update**

```bash
#!/bin/bash
# sync_payment_service_upgrade.sh: Update all regions atomically

PAYMENT_VERSION="v1.9.0"  # Target version

echo "Executing synchronized payment-service upgrade to $PAYMENT_VERSION"

# Branch strategy: Create feature branch that updates all three regions
git checkout -b chore/payment-service-sync-$PAYMENT_VERSION main

# Update each region's submodule to same version
for region in us-east eu apac; do
    SERVICE_DIR="services/api-$region"
    
    echo "Updating $SERVICE_DIR..."
    cd "$SERVICE_DIR"
    cd vendor/payment-service
    
    git fetch origin
    git checkout "refs/tags/$PAYMENT_VERSION"
    
    cd ../../..
    
    # Stage the submodule update
    git add "$SERVICE_DIR/vendor/payment-service"
done

# Single atomic commit
git commit -m "chore: synchronize payment-service to $PAYMENT_VERSION across all regions

Updates:
  - services/api-us-east: payment-service → $PAYMENT_VERSION
  - services/api-eu: payment-service → $PAYMENT_VERSION
  - services/api-apac: payment-service → $PAYMENT_VERSION

Compliance: All regions now use identical payment-service version
Tested: Regional CI/CD gates passed
Approved: Security + Compliance teams"

# Create PR (will be reviewed by region leads + compliance)
git push origin chore/payment-service-sync-$PAYMENT_VERSION

echo "✓ Coordinated update branch created"
echo "  Create PR and coordinate region leads to approve"
echo "  Upon merge: All regions update simultaneously"
```

**Step 4: Deploy with Coordination**

```yaml
# .github/workflows/coordinated-regional-deploy.yml
name: Coordinated Regional Deployment

on:
  push:
    branches: [main]

jobs:
  pre-deploy-validation:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Verify all regions on same payment-service version
        run: |
          versions=$(git submodule status | grep payment-service | awk '{print $1}' | sort -u | wc -l)
          if [ "$versions" -gt 1 ]; then
            echo "❌ Regional payment-service versions differ!"
            exit 1
          fi
          echo "✓ All regions synchronized"

  deploy-regions-sequentially:
    needs: pre-deploy-validation
    runs-on: ubuntu-latest
    strategy:
      matrix:
        region: [us-east, eu, apac]
      max-parallel: 1  # Deploy one region at a time
    steps:
      - uses: actions/checkout@v3
      
      - name: Deploy to ${{ matrix.region }}
        run: |
          echo "Deploying to ${{ matrix.region }}..."
          ./scripts/deploy-region.sh ${{ matrix.region }}
          
      - name: Health check - ${{ matrix.region }}
        run: ./tests/health-check-region.sh ${{ matrix.region }}
        
      - name: Notify deployment complete
        run: |
          echo "✓ ${{ matrix.region }} deployment successful"
          # Notification to region lead
```

**Best Practices Applied**

1. **Version Consistency as Policy:** Enforced at CI/CD level (not manual discipline)
2. **Atomic Multi-Region Update:** Single commit updating all regions simultaneously
3. **Sequential Regional Deployment:** One region deploys, validated before next region
4. **Compliance Tracking:** Commit message and PR provide audit trail
5. **Coordinated Communication:** PagerDuty/Slack notifications to region leads before deploy

### 13.2 Scenario: Recovering from Accidental Force-Push to Production Branch

**Problem Statement**

2 AM: Engineer accidentally does `git push --force` to main branch - overwrites 6 recent commits (3 hours of bug fixes). 200 developers pull and get corrupted repository. Subsequent deploys fail. SLA violation risk: 15-minute RTO target.

**Architecture Context**

```
Production Deployment Pipeline:
  git commit → push to main → GitHub Actions CI
  → All checks pass → Auto-deploy to production
  → Monitoring alerts if issues

Current state (2:15 AM):
  - Force-push occurred 2:05 AM
  - 40 developers have already pulled (corrupted state)
  - CI/CD pipeline blocked (can't find commits)
  - Production still running v1.2.5 (lucky - 3 attempts failed)
```

**Step-by-Step Recovery**

**Step 1: Detect and Declare Incident (Within 2 Minutes)**

```bash
#!/bin/bash
# Automated detection + alert

# GitHub webhook detects force-push
if [ "$force_push" == "true" ]; then
    # Trigger automated incident response
    
    echo "🚨 INCIDENT: Force-push detected to main"
    
    # Step 1: Immediate notification
    curl -X POST -H 'Content-type: application/json' \
        --data '{"text":"INCIDENT #9234: Force-push to main detected. Initiating recovery. ETA: 5 min"}' \
        "$SLACK_WEBHOOK_URL"
    
    # Page on-call engineer
    curl -X POST "https://events.pagerduty.com/v2/enqueue" \
        -H 'Content-Type: application/json' \
        -d '{
            "routing_key": "'"$PD_ROUTING_KEY"'",
            "event_action": "trigger",
            "payload": {
                "summary": "Force-push to main branch - immediate recovery needed",
                "severity": "critical",
                "source": "git-webhook"
            }
        }'
fi
```

**Step 2: Find the Lost Commits (Immediately)**

```bash
#!/bin/bash
# recover_from_force_push.sh

echo "Recovering from force-push incident..."

# Fetch from mirror repository (should have full history)
git remote add mirror https://github.com/company/main-mirror.git
git fetch mirror

# Find missing commits
git reflog origin/main | head -20

# Output should show:
# abc123 origin/main@{0}: push (forced-update): commit message
# def456 origin/main@{1}: commit: important fix
# ghi789 origin/main@{2}: commit: critical hotfix

# The commits before the force-push are in reflog!
LOST_COMMITS="def456 ghi789 jkl012"  # Commits that were overwritten

echo "Lost commits found:"
for commit in $LOST_COMMITS; do
    git show --stat $commit | head -5
done
```

**Step 3: Restore Main Branch (1-2 Minutes)**

```bash
#!/bin/bash
# Restore to state before force-push

# Get commit before force-push from reflog
PRE_FORCE_PUSH_SHA=$(git reflog origin/main | grep -B1 "forced-update" | tail -1 | awk '{print $1}')

echo "Restoring main to: $PRE_FORCE_PUSH_SHA"

# Reset main to recovered state
git checkout main
git reset --hard $PRE_FORCE_PUSH_SHA

# Push back (with --force-with-lease as safeguard, but it will succeed)
git push origin main --force-with-lease

echo "✓ Main branch restored"
git log --oneline | head -10  # Verify recovered commits visible
```

**Step 4: Notify and Resync Developers (3-5 Minutes)**

```bash
#!/bin/bash
# notify_and_resync.sh

cat > /tmp/incident-recovery.md <<'EOF'
# Incident #9234: Force-Push Recovery

**Timeline:**
- 2:05 AM: Force-push to main detected
- 2:07 AM: Lost commits recovered from reflog
- 2:08 AM: Main branch restored
- 2:10 AM: All developers notified

**Action Required (Developer):**
```
git fetch --all
git reset --hard origin/main
git status  # Should show clean
```

**Verification:**
```bash
# Verify commits are back
git log --oneline | grep "important fix"  # Should be visible
git log --oneline | grep "critical hotfix"  # Should be visible
```

**Post-Incident:**
1. Force-push permissions review (who had permission?)
2. Increase reflog retention (6 months minimum)
3. Add pre-push hook to warn about force-push
4. Mirror repository backup verification quarterly
EOF

# Send to Slack
curl -X POST -H 'Content-type: application/json' \
    --data "{\"text\":\"Incident Recovery Complete\n\`\`\`$(cat /tmp/incident-recovery.md)\`\`\`\"}" \
    "$SLACK_WEBHOOK_URL"

# Broadcast email to all developers
mail -s "Incident #9234: Force-Push Recovery - Action Required" \
    developers@company.com < /tmp/incident-recovery.md
```

**Step 5: Post-Incident Preventive Measures (Post-Recovery)**

```bash
#!/bin/bash
# Enforce branch protection to prevent future incidents

# GitHub CLI to update branch protection
gh api repos/owner/repo/branches/main/protection \
    --input - <<'EOF'
{
  "required_status_checks": {
    "strict": true,
    "contexts": ["ci/build", "ci/test", "security/scan"]
  },
  "required_pull_request_reviews": {
    "dismiss_stale_reviews": true,
    "require_code_owner_reviews": false,
    "required_approving_review_count": 1
  },
  "enforce_admins": true,
  "allow_force_pushes": false,
  "allow_deletions": false
}
EOF

# Local pre-push hook warning
cat > .git/hooks/pre-push <<'EOF'
#!/bin/bash
if [[ "$2" == *"--force"* ]] || [[ "$2" == *"-f"* ]]; then
    echo "⚠️  WARNING: You're about to force-push!"
    echo "   Main, develop, and release/* branches cannot be force-pushed"
    echo "   Add --no-verify to bypass this check (emergency only)"
    
    if [[ "$1" == "origin" ]] && [[ "$3" =~ ^refs/heads/(main|develop|release) ]]; then
        echo "❌ ERROR: Cannot force-push production branches"
        exit 1
    fi
fi

exit 0
EOF

chmod +x .git/hooks/pre-push

# Increase reflog retention
git config --global gc.reflogExpire "6 months"
git config --global gc.reflogExpireUnreachable "6 months"
```

**Best Practices Applied**

1. **Automated Detection:** Webhook detects force-push immediately
2. **Mirror Repository:** Secondary copy ensures recovery is always possible
3. **Reflog Retention:** Extended to 6 months (instead of default 30 days)
4. **Branch Protection:** Enforce via GitHub settings (not manual discipline)
5. **RTO Achieved:** Full recovery to previous state in ~5 minutes

### 13.3 Scenario: Cherry-Picking Hotfix Across Multiple Release Branches

**Problem Statement**

A critical security vulnerability (CVE-2024-1234) discovered in authentication middleware. Affects:
- v2.5 (currently in production)
- v2.4 (still supported for 2 weeks)
- v2.3 (LTS - supported for 1 more year)
- v3.0 (beta with selected customers)

Must release patches: v2.5.4, v2.4.8, v2.3.11, v3.0-beta.7 all within 4 hours. Security team demands: Single fix, applied identically across all versions.

**Architecture Context**

```
Release Branch Strategy (Gitflow variant):
  main (v3.0 development)
      ↑
      └─ v3.0-beta branch
  
  release/v2.5 (latest production)
  release/v2.4 (LTS support)
  release/v2.3 (LTS support)

Fix application flow:
  1. Fix committed to main (v3.0)
  2. Cherry-pick to v3.0-beta branch
  3. Cherry-pick to release/v2.5 → tag v2.5.4
  4. Cherry-pick to release/v2.4 → tag v2.4.8
  5. Cherry-pick to release/v2.3 → tag v2.3.11
```

**Step-by-Step Resolution**

**Step 1: Create Fix on Latest Branch (Main)**

```bash
#!/bin/bash
# Create and validate fix on main first

git checkout main
git pull origin main

# Create hotfix branch
git checkout -b security/CVE-2024-1234-auth-bypass

# Fix the vulnerability
# File: src/auth/middleware.go
# Issue: Missing input validation on JWT claims

cat > src/auth/middleware.go <<'EOF'
package auth

import (
    "crypto/sha256"
    "fmt"
)

// ✓ FIXED: Added validation of JWT claims to prevent bypass
func ValidateJWTClaims(token string) error {
    // Previously: No validation on claim expiration
    now := time.Now().Unix()
    
    claims, err := parseJWT(token)
    if err != nil {
        return fmt.Errorf("invalid token: %w", err)
    }
    
    // ✓ NEW: Strict expiration validation
    if claims.ExpiresAt < now {
        return fmt.Errorf("token expired")
    }
    
    // ✓ NEW: Require specific claim fields
    if claims.Subject == "" || claims.Issuer != "auth.company.com" {
        return fmt.Errorf("invalid token claims")
    }
    
    return nil
}
EOF

# Commit fix
git commit -am "security: fix JWT validation bypass in auth middleware

This prevents attackers from using expired or forged JWT tokens.

Fix:
  - Strict expiration validation
  - Require issuer verification
  - Validate subject claim

CVE: CVE-2024-1234
Severity: Critical
Affected: v2.3+
CVSS Score: 9.1

Security-Reviewed-By: @security-team
Signed-Off-By: john@company.com"

# Get the commit SHA for cherry-picking
SECURITY_FIX_SHA=$(git rev-parse HEAD)
echo "Security fix committed: $SECURITY_FIX_SHA"
```

**Step 2: Test Fix Thoroughly**

```bash
#!/bin/bash
# validate_security_fix.sh: Comprehensive testing before releasing

echo "Security Fix Validation"
echo "======================="

# Unit tests
echo "1. Running security-specific tests..."
make test-security

# Regression tests
echo "2. Regression testing..."
make test

# Security scanning
echo "3. Running SAST..."
./tools/security-scan.sh src/auth/

# Manual validation
echo "4. Manual verification..."
# Verify expired token is rejected
curl -v -H "Authorization: Bearer <expired_token>" \
    https://localhost:8080/api/v1/users

# Expected: 401 Unauthorized
```

**Step 3: Cherry-Pick Across Release Branches**

```bash
#!/bin/bash
# cherry_pick_security_fix.sh: Apply fix to all supported versions

SECURITY_FIX_SHA="abc1234"  # Commit from Step 1
VERSIONS=("v3.0-beta:v3.0-beta.7" "v2.5:v2.5.4" "v2.4:v2.4.8" "v2.3:v2.3.11")

for version_pair in "${VERSIONS[@]}"; do
    BRANCH=$(echo "$version_pair" | cut -d':' -f1)
    TAG=$(echo "$version_pair" | cut -d':' -f2)
    
    echo "Processing branch: $BRANCH → tag: $TAG"
    
    # Checkout release branch
    git checkout "$BRANCH"
    git pull origin "$BRANCH"
    
    # Cherry-pick the security fix
    if ! git cherry-pick "$SECURITY_FIX_SHA"; then
        echo "⚠️  Cherry-pick conflict detected for $BRANCH"
        echo "   Manual resolution required"
        
        # Automatic conflict resolution where possible
        git checkout --ours src/auth/middleware.go
        git add src/auth/middleware.go
        git cherry-pick --continue
    fi
    
    # Verify fix is present
    if ! grep -q "claims.ExpiresAt < now" src/auth/middleware.go; then
        echo "❌ ERROR: Security fix not properly applied to $BRANCH"
        exit 1
    fi
    
    # Update version
    sed -i "s/VERSION=.*/VERSION=$TAG/" Makefile
    git add Makefile
    git commit --amend --no-edit -m "chore: bump version to $TAG"
    
    # Tag release
    git tag -a "$TAG" -m "Security release - CVE-2024-1234 patch
    
This release includes critical security fix:
  https://nvd.nist.gov/vuln/detail/CVE-2024-1234
    
Changelog:
  - [SECURITY] Fixed JWT validation bypass in auth middleware"
    
    # Push
    git push origin "$BRANCH"
    git push origin "$TAG"
    
    echo "✓ $BRANCH: cherry-pick successful, tagged as $TAG"
done

echo ""
echo "Summary: Security fix applied to all supported versions"
git tag | grep -E "v2.3|v2.4|v2.5|v3.0-beta" | tail -5
```

**Step 4: Coordinated Deployment**

```yaml
# .github/workflows/security-patch-deploy.yml
name: Security Patch Deployment (CVE-2024-1234)

on:
  push:
    tags:
      - v2.3*
      - v2.4*
      - v2.5*
      - v3.0-beta*

jobs:
  deploy-security-patch:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Verify security fix is present
        run: |
          if ! grep -q "claims.ExpiresAt < now" src/auth/middleware.go; then
            echo "❌ Security fix not found in checked-out code!"
            exit 1
          fi
          echo "✓ Security fix verified"
      
      - name: Build and test
        run: make test
      
      - name: Create Docker image
        run: docker build -t company/api:${{ github.ref_name }} .
      
      - name: Deploy to staging
        env:
          VERSION: ${{ github.ref_name }}
        run: |
          kubectl set image deployment/api api=company/api:$VERSION -n staging
          kubectl rollout status deployment/api -n staging
      
      - name: Smoke tests
        run: ./tests/security-smoke-tests.sh
      
      - name: Deploy to production
        run: |
          # Staggered: Deploy to 1 region, monitor, then others
          ./scripts/canary-deploy.sh ${{ github.ref_name }}
      
      - name: Notify security team
        run: |
          curl -X POST $SLACK_WEBHOOK \
            -H 'Content-type: application/json' \
            -d '{
              "text": "✓ Security patch deployed: CVE-2024-1234\n'${{ github.ref_name }}' released"
            }'
```

**Best Practices Applied**

1. **Single Source of Truth:** Fix created once, applied to all versions
2. **Systematic Cherry-Picking:** Automated across all supported branches
3. **Verification at Each Step:** Confirm fix present before deployment
4. **Coordinated Release:** All versions released in controlled manner
5. **Historical Traceability:** Commit message links to CVE database

---

## 14. Most Asked Interview Questions (Senior DevOps Level)

### Question 1: "We have a monorepo with 200 services. Our CI/CD pipeline takes 2 hours to run complete tests. Developers complain about slow feedback loops. How would you redesign the Git workflow and CI strategy?"

**Expected Answer (Senior DevOps):**

"This is a classic monorepo scaling problem. The issue isn't Git—it's how changes are coordinated. Here's my approach:

**Phase 1: Diagnose (Week 1)**
```bash
# Identify slowest tests
make test --verbose > /tmp/times.txt
# Extract: Which tests, which services?
```

**Phase 2: Selective Building (Week 2-3)**
```
Current: Every commit → Test all 200 services
Better: Every commit → Test ONLY changed services + dependents

Implementation:
1. Detect changed files: git diff origin/main...HEAD --name-only
2. Map changed files to services: services/payment → ['payment']
3. Calculate dependents: services/api depends on payment → ['api']
4. Test only: payment + api (reduce scope 95%)
```

**Phase 3: Test Stratification**
- Unit tests: 100ms each, run in parallel (5 min total)
- Integration: 30s each, run for changed services (2 min)
- E2E: Static suite, 15 min (run once per release, not per commit)
- Smoke: Quick checks on deploy, 2 min

**Phase 4: Git Branching for Feedback**
- Trunk-based development (main always deployable)
- Feature branches <8 hours old (force rebase to main)
- Pre-merge with selective CI (5-10 min feedback)
- Post-merge: Full suite runs asynchronously (doesn't block merge)

**Result:**
- Developer feedback: 5-10 minutes (from 2 hours)
- Full test suite: Runs overnight, developers see results in morning
- Confidence: High (nothing breaks)

**Real-world: This is what Google does with tens of thousands of services.**"

### Question 2: "During an incident, we discovered developers committed database credentials to Git history. They were 'removed' but the old commits still exist. What's the incident response?"

**Expected Answer (Senior DevOps):**

"This is a critical security incident. Here's the proper response:

**Immediate (First 5 Minutes):**
1. Assume credentials are compromised
2. Rotate all secrets immediately (don't wait)
3. Assess blast radius: 'What could an attacker do with these creds?'

**Response (Next 30 Minutes):**
```bash
# Find all instances in history
git log --source --all -S 'database_password' --format=%h

# Rewrite history (irreversible, affects all developers)
git filter-repo --path-glob 'config*.yaml' \
    --replace-text /path/secret-patterns.txt

# Push to all developers: git clone --mirror; cd mirror.git; git push origin --mirror
```

**Why git reset doesn't work here:**
- `git reset` only moves HEAD; old commits still exist
- Anyone cloning before reset gets the credentials
- Need `filter-repo` to rewrite history (creates new SHAs)

**Post-Incident:**
1. Implement pre-commit hook:
   ```bash
   git-secrets scan --cached  # Detect before commit
   ```

2. Update CI/CD:
   ```yaml
   - name: Scan for secrets
     run: |
       git log HEAD~10..HEAD -p | grep -iE 'password|api.key|secret' && exit 1
   ```

3. Prevent recurrence:
   - `.gitignore` for all config files
   - Use environment variables/vaults (never in Git)
   - Enforce signed commits (trace to specific developer)

**Cultural change:** Educate: 'Git is not a secret store; use HashiCorp Vault'

This is why branch protection + code review catch 80% of this stuff."

### Question 3: "We transitioned from GitHub Flow to Gitflow 6 months ago. Now we have release/v2.5, release/v2.4, release/v2.3, develop, and 50 feature branches. Merging is chaos. Did we make a mistake?"

**Expected Answer (Senior DevOps):**

"You didn't make a mistake in choosing Gitflow; you made a mistake in **not automating** Gitflow. Here's the honest assessment:

**Why Gitflow is Hard to Maintain:**
- Many concurrent branches = high merge conflict risk
- Manual coordination = human error
- Long-lived branches = integration debt accumulates

**But Gitflow is Right For:**
- Multiple production versions (v2.5, v2.4, v2.3)
- Scheduled releases (quarterly, not continuous)
- Regulatory requirements (plan releases in advance)

**You're in pain because:**
1. Merging feature branches manually to develop (should be automatic)
2. Cherry-picking hotfixes between branches (should be automatic)
3. No clear branch protection policies

**Fix It:**

```yaml
# Automate the coordination
- name: Auto-merge feature to develop
  if: github.event.pull_request.base.ref == 'feature/**'
  run: |
    gh pr merge --auto --squash
    
    # Then auto-create PR from develop → release/v2.5
    gh pr create --base release/v2.5 \
      --title "Merge develop → v2.5" \
      --body "Auto-generated from develop changes"
```

**Real solution:**

If your pain is > 20% of development time, you actually want **Trunk-Based Development**:

```
main (always deployable)
  ↑
  ├─ Feature branches (1-2 days, rebase often)
  └─ Release tags (v2.5.0, v2.5.1, v2.5.2 all from main)

Why this works:
- Single source of truth (main)
- No long-lived branches
- Frequent integration (catch issues early)
- Easy to backport fixes (cherry-pick hotfix to v2.5.0..v2.5.2 tags)
```

**My honest take: Stick with Gitflow IF:**
- You genuinely have 4+ versions in production
- You deploy on a schedule (not continuous)
- Team size is consistent

**Switch to Trunk-Based IF:**
- You're doing continuous deployment (most companies now)
- Merge conflict pain is >30% of sprint time
- You have <3 production versions"

### Question 4: "We use submodules for 12 shared libraries. Developers constantly forget `git submodule update --recursive`. What's the best solution?"

**Expected Answer (Senior DevOps):**

"This is a solved problem. You need **three layers of enforcement** (not just one):

**Layer 1: Automation (Git Hooks)**
```bash
# .git/hooks/post-checkout (automatic after git checkout)
#!/bin/bash
git submodule update --recursive --init

# .git/hooks/post-merge (automatic after git pull)
#!/bin/bash
git submodule update --recursive --init
```

**Layer 2: CI/CD Validation**
```yaml
- name: Verify all submodules initialized
  run: |
    git submodule status | grep -E '^\-' && {
      echo "❌ Uninitialized submodules found"
      exit 1
    }
```

**Layer 3: Make It Explicit**
```bash
# Makefile or setup script
setup:
  git submodule update --recursive --init
  make build

dev-setup:
  ./scripts/setup-dev-env.sh  # Handles submodules + env setup
```

**But honestly? The real issue is that submodules are error-prone.**

**Better alternatives:**

1. **For shared libraries:** Use npm workspaces, Gradle multi-project, or Poetry workspaces
   - Developers use same branch for all dependencies
   - No separate versioning headaches

2. **For truly independent versioning:** Use package managers (npm, PyPI, Maven)
   ```
   shared-auth v2.0.0 → Package in npm registry
   All services: npm install @company/shared-auth@2.0.0
   
   Pro: Clear versioning, standard tooling
   Con: Slight latency (package registry access)
   ```

3. **For monorepo:** Skip submodules entirely
   ```
   monorepo/
     services/auth/
     services/api/
     libraries/shared-auth/
   
   Everything versioned together
   ```

**My recommendation:**
- If services are tightly coupled → Use monorepo (no submodules needed)
- If services have independent versions → Use package registry (npm/PyPI)
- If you must use submodules → Automate all three layers above

The fact that developers 'forget' is a design smell. Fix the design."

### Question 5: "A developer rebased their feature branch 50 times during code review iterations. The final commit is clean, but the history is messy. During review, comments reference commits that no longer exist. How should we handle this?"

**Expected Answer (Senior DevOps):**

"This is about code review workflow and branch hygiene. Here's the perspective:

**What went wrong:**

```
Rebase Iteration 1:  A' B' C' D'
Code review comments on commit D
Dev fixes: rebase again
Rebase Iteration 2:  A'' B'' C'' D''
Comments on old D no longer match new D''
Historical comments become confusing
```

**The right approach:**

**Option 1: Squash Before Merging**
```bash
# This is the CORRECT behavior for code review
git merge --squash feature/xyz

# Result: Single clean commit on main
# Historical PR discussion remains in GitHub
# No messy rebases visible to mainline
```

**Option 2: Organized Rebases (for learning)**
```
During code review iterations:
  Iteration 1: git commit --amend (fix on top of current)
  Iteration 2: git commit --amend (amends previous)
  
Result: Same commit SHA, updated content
# Comments always reference same commit

But then:
  Pre-merge: git rebase -i main (clean up if needed)
  Merge: git merge --no-ff feature/xyz (preserves feature branch history)
```

**The policy I'd recommend:**

```
Feature branches: Developers can rebase/amend as much as needed
                  (history is malleable before merge)

Main branch:      Single source of truth
                  - Either merge commit (shows feature branch integration)
                  - Or squash (clean, linear history)
                  - NEVER rebase (destroys history)

Code review:      Happens on PR (GitHub/GitLab comment thread)
                  - Not tied to commit SHAs
                  - Comments available forever
                  - Separate from Git history
```

**Practical enforcement:**
```yaml
# Prevent rebasing main/develop
.git/hooks/pre-rebase:
  if [[ $(git rev-parse --abbrev-ref HEAD) == 'main' ||
        $(git rev-parse --abbrev-ref HEAD) == 'develop' ]]; then
    echo 'Cannot rebase production branches'
    exit 1
  fi
```

**Real-world: This is why squash-merge is popular for code review workflows. It:**
- Keeps feature branch history clean (rebases happen locally)
- Creates single logical commit on main
- Preserves full PR discussion off-chain
- Simplifies `git log main` (linear, readable history)

**My take: Stop caring about the feature branch history. It's temporary. What matters is the commit you're adding to main.**"

### Question 6: "How would you structure Git workflow and CI/CD for a company deploying to both AWS and on-premises? They have different compliance requirements."

**Expected Answer (Senior DevOps):**

"This requires separating **trust boundaries** in Git. Here's the architecture:

```
monorepo/
  ├── services/
  │   ├── payment-api/          (AWS only - PCI-DSS)
  │   ├── core-service/         (AWS + On-prem - Internal use)
  │   ├── compliance-engine/    (On-prem only - HIPAA)
  │   └── public-api/           (AWS only - Public)
  ├── infra/
  │   ├── aws/                  (CloudFormation, AWS-specific)
  │   ├── on-prem/              (Kubernetes YAML, On-prem-specific)
  │   └── shared/               (Docker compose, universal)
  ├── compliance/
  │   ├── aws/policies/         (AWS-specific audit configs)
  │   └── on-prem/policies/     (On-prem-specific audit configs)
  └── .github/workflows/
      ├── build-aws.yml         (AWS deployment pipeline)
      └── build-on-prem.yml     (On-prem deployment pipeline)
```

**Git Branching Strategy:**
```
main:                (production-ready code; universal)
release/aws/*:       (AWS-specific releases; can diverge)
release/on-prem/*:   (On-prem-specific releases; can diverge)
feature/*:           (development; neutral)
```

**Compliance Enforcement:**

```yaml
# .github/workflows/compliance-check.yml

jobs:
  pre-deployment-audit:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      # AWS Path: PCI-DSS checks
      - name: AWS Compliance - PCI-DSS
        if: github.ref == 'refs/heads/release/aws/*'
        run: |
          # Verify encrypted storage
          grep -r "encryption: true" infra/aws/ || exit 1
          # Verify no hardcoded secrets
          git diff HEAD~1 | grep -iE 'password|api.key' && exit 1
          # Verify IAM least-privilege
          ./compliance/aws/check-iam-policy.sh
      
      # On-Prem Path: HIPAA checks
      - name: On-Prem Compliance - HIPAA
        if: github.ref == 'refs/heads/release/on-prem/*'
        run: |
          # Verify audit logging
          grep -r "audit_logging: enabled" infra/on-prem/
          # HIPAA encryption requirements
          ./compliance/on-prem/check-hipaa.sh
```

**Secrets Management Differs:**

```
AWS Path:
  1. Credentials → AWS Secrets Manager
  2. CI/CD → Assume role via OIDC
  3. Deployment → Use role credentials
  
On-Prem Path:
  1. Credentials → HashiCorp Vault (self-hosted)
  2. CI/CD → Authenticate to Vault
  3. Deployment → Retrieve from Vault
```

**Implementation:**

```yaml
# AWS Deployment
jobs:
  deploy-aws:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
    steps:
      - uses: aws-actions/configure-aws-credentials@v2
        with:
          role-to-assume: arn:aws:iam::${{ env.AWS_ACCOUNT_ID }}:role/GitHub-Deploy
          aws-region: us-east-1
      
      - run: ./scripts/deploy-aws.sh

# On-Prem Deployment
jobs:
  deploy-on-prem:
    runs-on: self-hosted  # On-prem runner
    steps:
      - uses: hashicorp/vault-action@v2
        with:
          url: https://vault.company.local:8200
          method: jwt
          path: gh-actions
          role: gh-actions-deploy
          secretPath: secret/data/on-prem/deploy
      
      - run: ./scripts/deploy-on-prem.sh
```

**Key Insights:**

1. **Separate Release Branches:** AWS and On-Prem can diverge if compliance needs differ
2. **Separate Runners:** On-Prem deployment requires on-prem runner (network access)
3. **Separate CI/CD Logic:** Each path has different tooling, secrets manager, audit log
4. **Shared Code Where Possible:** Services run unchanged in both environments
5. **Compliance Enforcement:** Automated checks before approval/deployment

**This is how companies like HashiCorp and GitHub handle multi-environment deployments.**"

### Question 7: "We accidentally merged a feature branch to main that had breaking API changes. We discovered it 2 days later during system tests. Rolling back is risky (other commits depend on the API). What's the recovery strategy?"

**Expected Answer (Senior DevOps):**

"This is a common scenario. Immediate vs. safe recovery differs based on blast radius.

**Assess Blast Radius (First 5 Minutes):**
```bash
# How many commits have landed since the breaking change?
git log --oneline <breaking-commit>..HEAD | wc -l

# Do those commits depend on the breaking API?
git diff <breaking-commit>~1..<breaking-commit> -- src/api.go | grep -i "deprecate\|remove"

# If no commits depend on old API shape → safe rollback
# If commits depend on new shape → need different strategy
```

**Scenario 1: Safe Rollback (Clean revert; no dependencies)**

```bash
# Find breaking commit
# git log --oneline main | grep "feature/breaking"  → abc123

# Option A: Revert the commit (creates inverse commit)
git revert abc123
git push origin main

# Why revert not reset?
# - Preserves history (you can see what broke system)
# - Doesn't affect commits built on top
# - Audit trail shows: 'We introduced this, then removed it'

# Database/API state recovery
# - Revert database schema: Run rollback migration
# - Notify dependent services: "API endpoint restored to v1"
```

**Scenario 2: Risky Rollback (Later commits depend on breaking change)**

```
Timeline:
  Commit abc123: Remove /api/v1/users endpoint
  Commit def456: Update dashboard to call /api/v2/users (depends on removal)
  Commit ghi789: Update tests for v2
  
Problem: Can't revert abc123 without breaking def456, ghi789

Strategy: Shadow both API versions (not rollback but forward)
```

```bash
# Git approach: Merge branch that restores /v1 endpoint
git checkout -b restore/api-v1
git revert abc123
git commit --amend -m "restore: re-add /api/v1/users for backward compatibility

Reason: /api/v2/users clients not ready; need gradual migration

Timeline:
  Week 1: Both v1 + v2 available
  Week 2: Notify clients to migrate to v2
  Week 3: Deprecate v1 (500 warning)
  Week 4: Remove v1"

git push origin restore/api-v1

# Create PR for code review
gh pr create --base main --title "Restore /api/v1 for backward compatibility"
```

**Scenario 3: Prevent This in Future**

```yaml
# .github/workflows/api-breaking-change-detection.yml

on: [pull_request]

jobs:
  detect-breaking-changes:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      - name: Check for API breaking changes
        run: |
          # Detect removed/renamed API endpoints
          git diff origin/main...HEAD -- src/api.go | grep -E '^\-.*@(GET|POST|DELETE)' && {
            echo "❌ Breaking change detected"
            echo "   Removed endpoints must be deprecated first"
            echo "   See: https://company.com/api-deprecation-policy"
            exit 1
          }
      
      - name: Validate API versioning
        run: |
          # All API changes must include version bump
          grep -q 'api_version' src/api.go || {
            echo "❌ API version not updated"
            exit 1
          }
      
      - name: Require changelog entry
        run: |
          grep -q "## Unreleased" CHANGELOG.md && \
          grep -q "- BREAKING" CHANGELOG.md || {
            echo "❌ Breaking change not documented in CHANGELOG.md"
            exit 1
          }
```

**Policy I'd enforce:**

```
1. API deprecation is gradual (never instant removal)
   - v1.0: New endpoint introduced (old still supported)
   - v1.5: Old endpoint deprecated (headers warn)
   - v2.0: Old endpoint removed

2. Code review checklist
   - Have you checked who calls this endpoint?
   - Have you notified dependent teams?
   - Is there a migration path?

3. Rollback drills quarterly
   - Mock scenario: Service API becomes unavailable
   - How to recover? Practice it.
```

**Real-world: This is why Twitter, Stripe, etc. version their APIs. Breaking changes cost money.**"

### Question 8: "We're migrating from a polyrepo (20 separate Git repositories) to a monorepo. What's the safest migration strategy to avoid losing history or confusing developers?"

**Expected Answer (Senior DevOps):**

"This is a major infrastructure decision. Here's how I'd execute it with zero downtime and zero data loss:

**Phase 1: Preparation (Week 1)**

```bash
#!/bin/bash
# 1. Audit all repositories
for repo in $(cat repos.txt); do
    COMMIT_COUNT=$(git -C "$repo" rev-list --count HEAD)
    SIZE=$(du -sh "$repo/.git" | cut -f1)
    LAST_COMMIT=$(git -C "$repo" log -1 --format=%ci)
    echo "$repo: $COMMIT_COUNT commits, $SIZE, last: $LAST_COMMIT"
done

# Output guides prioritization (migrate active repos first)
```

```bash
# 2. Create mirror backups (don't touch originals)
for repo in $(cat repos.txt); do
    git clone --mirror "$GIT_URL/$repo.git" "/backups/$repo.git"
done
```

**Phase 2: Gradual Migration (Weeks 2-4)**

```
Week 2: Migrate internal/non-critical repos
Week 3: Migrate services repos
Week 4: Final verification before cutting over
```

```bash
#!/bin/bash
# migrate_repository_to_monorepo.sh

MONOREPO="/path/to/monorepo"
SOURCE_REPO="https://github.com/company/repo-name.git"
TARGET_PATH="services/name"  # Where it goes in monorepo

cd "$MONOREPO"

# Step 1: Add source as remote
git remote add source "$SOURCE_REPO"
git fetch source

# Step 2: Use filter-repo to reorganize (preserves ALL history)
git filter-repo --path-rename ":$TARGET_PATH" \
    --source "$SOURCE_REPO" \
    --target-branch "import/repo-name"

# This creates temporary branch with source repo history at new path

# Step 3: Merge with full history preserved
git checkout import/repo-name
git checkout main
git merge import/repo-name --allow-unrelated-histories \
    -m "feat: migrate repo-name into monorepo

Preserves full commit history from original repository.
Source: $SOURCE_REPO
Location: $TARGET_PATH

All developers should update their clones:
  git clone https://github.com/company/monorepo.git
  
Or existing clones:
  git remote set-url origin https://github.com/company/monorepo.git
  git fetch origin
  git checkout main"

# Step 4: Verify history integrity
echo "Verifying migration..."
git log --all --oneline -- "$TARGET_PATH" | head -20  # First commits
git log --all --oneline -- "$TARGET_PATH" | tail -20  # Recent commits

# Count should match original repository
ORIGINAL_COUNT=$(git rev-list --count source/main)
MIGRATED_COUNT=$(git rev-list --count main -- "$TARGET_PATH")
if [ "$ORIGINAL_COUNT" -eq "$MIGRATED_COUNT" ]; then
    echo "✓ All commits from original repository present"
else
    echo "⚠️  WARNING: Commit count mismatch"
    echo "  Original: $ORIGINAL_COUNT"
    echo "  Migrated: $MIGRATED_COUNT"
fi

# Step 5: Cleanup
git branch -D import/repo-name
git remote remove source
```

**Phase 3: Parallel Development (Week 3-4)**

```
During migration:

Developers working in polyrepo:
  git commit → continue in old repos
  
Migration process runs in parallel:
  Migrations happening to monorepo
  
Before cutover:
  All repos migrated to monorepo
  Code is identical in both places
  
Cutover point (Friday end of day):
  Old repos: Mark as archived (no more work)
  New monorepo: Main branch now live
  Developers update clones
```

**Phase 4: Cutover Communication**

```bash
#!/bin/bash
# communicate_cutover.sh

CUTOVER_DATE="2024-03-24"
CUTOVER_TIME="5:00 PM UTC"

# Email to all developers
cat > /tmp/cutover-notice.md <<'EOF'
# Monorepo Migration - Cutover Notice

## Timeline
- **Friday 5 PM UTC**: Old repositories archived
- **Friday 5:05 PM UTC**: Monorepo becomes primary development branch
- **Saturday morning**: All access to old repos redirects to monorepo

## Action Required
1. Stage any uncommitted local work
2. After 5 PM UTC:
   ```
   # Option A: Fresh clone
   git clone https://github.com/company/monorepo.git
   
   # Option B: Update existing
   git remote set-url origin https://github.com/company/monorepo.git
   git fetch origin
   git checkout main
   ```

3. Update your IDE to point to new location:
   - Update `.git/config` remotes
   - Update continuous deployment configurations
   - Update container builds to reference new paths

## What Hasn't Changed
- All commit history is preserved
- All branches are available
- All blame/bisect/log commands work identically
- Credentials and access permissions remain the same

## Verification
After cutover, verify your setup:
```
git remote -v                    # Should show monorepo URL
git log services/your-service/   # Should show all your service history
```

## Support
- Issues: #monorepo-migration in Slack
- Questions: devops-team@company.com
EOF

# Send to all developers
mail -s "Monorepo Migration Cutover - Friday 5 PM UTC" \
    developers@company.com < /tmp/cutover-notice.md
```

**Phase 5: Post-Cutover Verification**

```bash
#!/bin/bash
# verify_migration_complete.sh

echo "Post-migration verification..."

# Check 1: All services present
for service in $(cat original-services.list); do
    if [ ! -d "services/$service" ]; then
        echo "❌ Service missing: $service"
        exit 1
    fi
done

# Check 2: No data loss
for service in $(cat original-services.list); do
    ORIGINAL_COUNT=$(git rev-list --count migrate-source/$service)
    MIGRATED_COUNT=$(git rev-list --count main -- services/$service)
    if [ "$ORIGINAL_COUNT" -ne "$MIGRATED_COUNT" ]; then
        echo "⚠️  Commit loss detected in $service"
    fi
done

# Check 3: Repository size reasonable
SIZE=$(du -sh .git | cut -f1)
if [ ${SIZE%G} -gt 50 ]; then  # > 50 GB is concerning
    echo "⚠️  Repository size: $SIZE (larger than expected)"
fi

echo "✓ Migration complete and verified"
```

**Best Practices Applied:**

1. **Backup Everything:** Mirror before touching
2. **Preserve History:** Full history from all repos
3. **Parallel Transition:** Old repos still work during migration
4. **Clear Communication:** Developers know exactly what to do
5. **Verification:** Automated checks ensure no data loss
6. **Gradual Rollout:** Non-critical repos first, then gradual increase

**Real-world data point: Google migrated 40,000 engineers from polyrepo to monorepo over 2 years. This is the proven strategy.**"

### Question 9: "How would you design a Git-based workflow for managing blue-green deployments and canary releases?"

**Expected Answer (Senior DevOps):**

"This requires integrating Git workflow with deployment infrastructure. Here's the architecture:

```
Git Structure:
  main              (production code; always tested)
  canary/*          (canary branch; targeted subset)
  blue              (current prod; stable)
  green             (next prod; ready to switch)

Deployment:
  1. Code merged to main
  2. CI/CD builds and tests
  3. Deploy to green (non-production)
  4. If green looks good: routes switch to green (blue-green deploy)
  5. Green becomes new blue; loop repeats
```

**Implementation:**

```yaml
# .github/workflows/blue-green-deploy.yml

on:
  push:
    branches: [main, canary/*]

env:
  REGISTRY: gcr.io/company
  BLUE_SLOT: us-east-slot-a
  GREEN_SLOT: us-east-slot-b

jobs:
  build:
    runs-on: ubuntu-latest
    outputs:
      image-digest: ${{ steps.build.outputs.digest }}
    steps:
      - uses: actions/checkout@v3
      
      - name: Build container
        id: build
        run: |
          docker build -t $REGISTRY/api:${{ github.sha }} .
          docker push $REGISTRY/api:${{ github.sha }}
          echo "digest=$(docker inspect --format='{{index .RepoDigests 0}}' ...)" >> $GITHUB_OUTPUT

  deploy-green:
    needs: build
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to green (non-production)
        run: |
          kubectl set image deployment/api-green \
            api=${{ env.REGISTRY }}/api:${{ github.sha }} \
            -n production
          
          kubectl rollout status deployment/api-green -n production

  smoke-tests:
    needs: deploy-green
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      
      - name: Test green deployment
        run: |
          # Run smoke tests against green
          SERVICE_URL=https://green.internal.company.com ./tests/smoke.sh
          
          # Verify green is healthy
          curl -f https://green.internal.company.com/health || exit 1
          
          # Load test: 10% of expected traffic
          ./tools/load-test.sh --target green --rate 0.1

  canary-decision:
    needs: smoke-tests
    runs-on: ubuntu-latest
    if: success()
    steps:
      - uses: actions/checkout@v3
      
      - name: Canary metrics evaluation
        id: canary-check
        run: |
          # Query metrics from green vs blue
          ERROR_RATE_GREEN=$(prometheus_query "error_rate{deployment='api-green'}" 5m)
          ERROR_RATE_BLUE=$(prometheus_query "error_rate{deployment='api-blue'}" 5m)
          
          # If error rate increased significantly, abort
          if (( $(echo "$ERROR_RATE_GREEN > $ERROR_RATE_BLUE * 1.5" | bc -l) )); then
            echo "canary-status=failed" >> $GITHUB_OUTPUT
            exit 1
          fi
          
          # Otherwise, ready to promote
          echo "canary-status=success" >> $GITHUB_OUTPUT
      
      - name: Create ticket for manual approval
        if: steps.canary-check.outputs.canary-status == 'success'
        run: |
          gh issue create --title "Ready for Blue-Green Swap: ${{ github.sha }}" \
            --body "Green deployment passed all checks. Approve to swap."

  promote-to-blue:
    needs: canary-decision
    runs-on: ubuntu-latest
    if: github.event.issue.state == 'closed'  # Manual approval via issue close
    steps:
      - name: Update routing to green (new blue)
        run: |
          # Gradually shift traffic from blue to green
          k put service api-blue-green-splitter \
            --traffic blue:0,green:100 \
            -n production
          
          sleep 30  # Monitor before finalizing
          
          # Swap blue/green labels for next iteration
          kubectl patch deployment api-blue \
            -p '{"spec": {"template": {"metadata": {"labels": {"slot": "old"}}}'}}
          
          kubectl patch deployment api-green \
            -p '{"spec": {"template": {"metadata": {"labels": {"slot": "current"}}}'}}

  rollback-if-needed:
    if: failure()
    runs-on: ubuntu-latest
    steps:
      - name: Revert routing to blue
        run: |
          k put service api-blue-green-splitter \
            --traffic blue:100,green:0 \
            -n production
      
      - name: Notify incident
        run: |
          curl -X POST $SLACK_WEBHOOK \
            --data '{"text": "⚠️  Blue-Green deploy rolled back due to failures"}'
```

**Git Canary Strategy:**

```bash
# For testing with subset of users:

git checkout -b canary/feature-xyz main

# Deploy only to canary slot (5% users)
# Users with: X-Canary-User: true header route to canary service

# If metrics look good: Merge to main → full blue-green deploy
git push origin canary/feature-xyz
gh pr create --base main  # Code review + approval

# Upon merge: Full rollout happens automatically
```

**Monitoring Integration:**

```python
# canary-rollout-decision.py

def should_promote_to_prod(green_metrics, blue_metrics):
    checks = {
        'error_rate': green_metrics['error_rate'] < blue_metrics['error_rate'] * 1.1,
        'latency': green_metrics['p99_latency'] < blue_metrics['p99_latency'] * 1.15,
        'cpu': green_metrics['cpu_avg'] < blue_metrics['cpu_avg'] * 1.2,
        'memory': green_metrics['mem_avg'] < blue_metrics['mem_avg'] * 1.2,
    }
    
    failed = [k for k,v in checks.items() if not v]
    if failed:
        print(f'Canary failed checks: {failed}')
        return False
    
    return True
```

**This is production-grade deployment strategy used by companies like Netflix, Uber, and Airbnb.**"

### Question 10: "Our company is highly regulated (HIPAA/SOC2). Every code change must be traceable to a requirement and auditable. How would you structure Git workflow to ensure this compliance?"

**Expected Answer (Senior DevOps):**

"This requires integrating Git with compliance framework. Here's the architecture:

```
Regulatory Requirements:
  1. Traceability: Every commit must link to requirement/ticket
  2. Code Review: All changes approved before deployment
  3. Sign-Off: Commits digitally signed (non-repudiation)
  4. Audit Trail: Who changed what, when, why
  5. Data Protection: No secrets in history
```

**Git Configuration for Compliance:**

```bash
#!/bin/bash
# setup-compliance-git.sh

# 1. Enforce signed commits (GPG/SSH)
git config --global commit.gpgsign true

# 2. Require commit message format
git config --global commit.template ~/.gitmessage

# 3. Set GPG key
gpg --list-keys  # Get your key ID
git config --global user.signingkey <KEY_ID>
```

**Commit Message Template (Compliance):**

```
# ~/.gitmessage

# REQUIRED: Format must match: (TYPE)-(NUM)-description
# Examples: (HIPAA)-2451-add-encryption  (SOC2)-1203-audit-logging

# Type: HIPAA, SOC2, PoC, Regulator, Technical, Security
# Number: From compliance tracking system (Jira ticket)

# Commit message format:

(TYPE)-(NUM): Brief description (50 chars max)

Detailed explanation of changes (why, not what):
  - Why was ISO27001 section 2.3 needed?
  - What business requirement does this satisfy?

Impact Assessment:
  - Security: No new vulnerabilities introduced (reviewed by: @security-team)
  - HIPAA: Ensures patient data is encrypted at rest and in transit
  - SOC2: Provides audit logging for access control

Attestations:
  Reviewed-By: @devsecops-team
  Approved-By: @compliance-officer
  Signed-Off-By: John Developer <john@company.com>
  
Jira: (HIPAA)-2451
Related: (HIPAA)-2450, (SOC2)-1203
```

**Enforcement via CI/CD:**

```yaml
# .github/workflows/compliance-checks.yml

on: [pull_request]

jobs:
  verify-compliance-requirements:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
        with:
          fetch-depth: 0
      
      # Check 1: All commits reference compliance requirement
      - name: Verify commit messages link to requirements
        run: |
          commitsUnassociated=0
          for commit in $(git log origin/main..HEAD --format=%H); do
            message=$(git log -1 --format=%B $commit)
            
            if ! echo "$message" | grep -qE '\((HIPAA|SOC2|PCI|GDPR)-[0-9]+\)'; then
              echo "❌ Commit $commit missing compliance reference"
              echo "   Message: $message"
              commitsUnassociated=$((commitsUnassociated + 1))
            fi
          done
          
          if [ $commitsUnassociated -gt 0 ]; then
            echo "ERROR: $commitsUnassociated commits lack compliance traceability"
            exit 1
          fi
      
      # Check 2: All commits signed
      - name: Verify commits are digitally signed
        run: |
          for commit in $(git log origin/main..HEAD --format=%H); do
            if ! git verify-commit $commit 2>/dev/null; then
              echo "❌ Unsigned commit: $commit"
              echo "   Sign with: git commit -S"
              exit 1
            fi
          done
      
      # Check 3: Security review attestation
      - name: Require security team review
        run: |
          # PR must have approval from @security-team
          reviewers=$(curl -s https://api.github.com/repos/owner/repo/pulls/$PR_NUMBER/reviews \
            | jq -r '.[] | select(.state=="APPROVED") | .user.login')
          
          if ! echo "$reviewers" | grep -q "@security-team"; then
            echo "❌ Security team approval required"
            exit 1
          fi
      
      # Check 4: No secrets committed
      - name: Secret scanning
        run: |
          git log origin/main..HEAD -p | \
            grep -iE 'password|api.key|secret|aws_secret|private_key' && {
            echo "❌ Potential secrets detected in commits"
            exit 1
          }
      
      # Check 5: Build audit trail
      - name: Generate audit log entry
        run: |
          cat > /tmp/audit.log <<EOF
          {
            "timestamp": "$(date -Iseconds)",
            "action": "code_review_initiated",
            "pr_number": "${{ github.event.number }}",
            "commits": [$(git log --format=%H origin/main..HEAD | paste -sd, -)],
            "reviewers": "$reviewers",
            "requirements": [$(git log --format=%B origin/main..HEAD | grep -oE '\((HIPAA|SOC2)-[0-9]+\)' | sort -u | paste -sd, -)]"
          }
          EOF
          
          # Store in audit system
          curl -X POST https://audit.company.local/api/logs \
            -H "Authorization: Bearer $AUDIT_TOKEN" \
            -d @/tmp/audit.log
```

**Server-Side Hooks Enforcement:**

```bash
#!/bin/bash
# .git/hooks/update (runs on server; cannot be bypassed)

while read oldrev newrev refname; do
    # Only enforce on main branch
    if [[ $refname != "refs/heads/main" ]]; then
        continue
    fi
    
    # Walk commits being pushed
    for commit in $(git rev-list $oldrev..$newrev); do
        # Requirement 1: Commit is signed
        if ! git verify-commit $commit 2>/dev/null; then
            echo "❌ Reject push: unsigned commit $commit"
            exit 1
        fi
        
        # Requirement 2: Commit message includes compliance reference
        message=$(git log -1 --format=%B $commit)
        if ! echo "$message" | grep -qE '\((HIPAA|SOC2|PCI|GDPR)-[0-9]+\)'; then
            echo "❌ Reject push: commit lacks compliance requirement"
            exit 1
        fi
        
        # Requirement 3: No secrets
        if git show $commit | grep -iE 'password|api.key|secret'; then
            echo "❌ Reject push: secrets detected in commit"
            exit 1
        fi
    done
done

exit 0
```

**Audit Trail Export:**

```bash
#!/bin/bash
# generate-compliance-report.sh

# For auditors: Show complete change history
git log main --format='%H|%an|%ae|%ad|%s' --date=iso -- . > audit-trail.csv

# For SOC2: Show who had access to sensitive paths
git log -p -- src/auth src/encryption | \
    grep -E '^commit|^Author:|^Date:|^index' > access-log.txt

# For HIPAA: Show all phi-related changes
git log --grep='phi\|pii\|patient' --format='%H %s' > phi-changes.txt

# Generate report for auditor
echo "Audit Report: $(date)"
echo "Repository: $(git config --get remote.origin.url)"
echo "Branch: main"
echo "Audit Period: $(date -d '1 month ago' +%Y-%m-%d) to $(date +%Y-%m-%d)"
echo ""
echo "Access Summary:"
echo "  Total commits: $(git rev-list --count main)"
echo "  Unique authors: $(git log --format=%an main | sort -u | wc -l)"
echo "  Compliance-linked commits: $(git log --grep='(HIPAA|SOC2)' --all-match | wc -l)"
echo "  Signed commits: $(git log --format=%G? main | grep -c '^G')"
echo ""
echo "Detailed log: audit-trail.csv"
```

**Real-World Impact:**

This is what companies like Twilio, Stripe, and GitHub use for compliance. The investment:
- Initial setup: 1-2 weeks
- Ongoing overhead: ~5% of developer time (signing commits, clear messaging)
- Compliance benefit: Passes audits; reduces audit cycle from 3 months to 2 weeks
- Risk reduction: Non-repudiation (can't deny you approved a change)

**The key insight: Make compliance part of Git workflow (automatic), not a separate process afterwards.**"

---

## Metadata & Version Information

- **Study Guide Version:** 3.0 (Complete + Extended)
- **Target Audience:** DevOps Engineers with 5-10+ years experience
- **Difficulty Level:** Advanced Production-Grade
- **Estimated Study Time:** 25-30 hours
- **Real-World Applicability:** Enterprise scenarios covered
- **Interview Readiness:** 10+ senior-level questions with detailed answers
- **Last Updated:** March 2026

---

**This comprehensive study guide now includes:**
- 12 sections covering all advanced Git topics
- 4 hands-on production scenarios with step-by-step procedures
- 10 senior-level interview questions with detailed, experience-focused answers
- Real-world shell scripts and YAML configurations
- ASCII diagrams for complex workflows
- Best practices from Google, Netflix, Stripe, GitHub, and other scale leaders

**Use this guide for:**
- Interview preparation (expect these exact questions)
- Incident response (troubleshooting procedures)
- Architectural planning (workflow design decisions)
- Team mentoring (explain concepts to junior engineers)
- Production operations (reference during deployments)

*This study guide represents enterprise-grade Git expertise and is suitable for senior engineering roles in companies ranging from early-stage startups to Fortune 500 organizations.*


- **Study Guide Version:** 1.0
- **Target Audience:** DevOps Engineers with 5-10+ years experience
- **Difficulty Level:** Advanced
- **Estimated Study Time:** 8-12 hours
- **Prerequisites:** Basic Git proficiency, experience with version control in team environments

---

*This study guide is designed to be incrementally extended with additional sections. Each section maintains independent clarity while supporting progressive deepening.*
