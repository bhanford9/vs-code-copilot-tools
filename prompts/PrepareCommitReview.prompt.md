---
name: prepare-commit-review
description: Create an isolated review branch from a specific set of commit SHAs for the code review pipeline
agent: REVIEW-CodeReviewOrchestrator
---

You are preparing a set of specific commits for code review. Your task is to create an isolated review branch that contains only the selected commits, so the existing code review pipeline can analyze them.

## Your Workflow

### 1. Gather Requirements from User

Ask the user for:
- **Commits to review**: List of commit SHAs (can be full or short form)
- **Conflict strategy**: How to handle conflicts if commits don't apply cleanly
  - `theirs`: Auto-resolve using the commit's version (default, works well for trunk-based development)
  - `abort`: Stop immediately if any conflict occurs
  - `skip`: Skip conflicting commits and continue with others
  - `ours`: Auto-resolve using the baseline's version

Example prompt to user:
```
Please provide:
1. List of commit SHAs to review (space or comma separated)
2. Conflict strategy: theirs/abort/skip/ours (default: theirs)
```

### 2. Validate Input and Determine Baseline

Before proceeding:

**Step 1: Verify commits exist**
```powershell
foreach ($commit in $commits) {
    $type = git cat-file -t $commit 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Error "Invalid commit SHA: $commit"
        return
    }
}
```

**Step 2: Sort commits chronologically**
```powershell
# Sort all commits by commit date (earliest to latest)
$sortedCommits = $commits | ForEach-Object {
    $commitSha = $_
    $commitDate = git show -s --format=%ct $commitSha
    $date = [DateTimeOffset]::FromUnixTimeSeconds($commitDate).DateTime
    
    [PSCustomObject]@{
        Sha = $commitSha
        Date = $date
        DateStr = git show -s --format=%ci $commitSha
    }
} | Sort-Object Date

Write-Host "Commits in chronological order:"
foreach ($commit in $sortedCommits) {
    Write-Host "  $($commit.Sha) - $($commit.DateStr)"
}

$earliestCommit = $sortedCommits[0].Sha
$commits = $sortedCommits.Sha

Write-Host ""
Write-Host "Earliest commit: $earliestCommit"
```

**Step 3: Determine baseline from parent of earliest commit**
```powershell
# Use the parent of the earliest commit as the baseline
$baseline = git rev-parse "$earliestCommit^"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Could not find parent of earliest commit: $earliestCommit"
    Write-Host "This commit may not have a parent (initial commit?)"
    return
}

$baselineMsg = git show -s --format=%s $baseline
Write-Host "Baseline determined: $baseline"
Write-Host "  (parent of earliest commit: $baselineMsg)"
```

**Step 4: Store current branch/ref for restoration**
```powershell
$originalRef = git rev-parse --abbrev-ref HEAD
if ($originalRef -eq "HEAD") {
    $originalRef = git rev-parse HEAD
}
```

### 3. Create Review Branch

Execute these steps:

```powershell
# Save current state
$originalRef = git rev-parse --abbrev-ref HEAD
if ($originalRef -eq "HEAD") {
    $originalRef = git rev-parse HEAD
}

# Generate unique branch name
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$reviewBranch = "code-review-temp-$timestamp"

# Create branch from baseline
git checkout -b $reviewBranch $baseline

Write-Host "✓ Created review branch: $reviewBranch from $baseline"
```

### 4. Apply Commits

For each commit (in chronological order), attempt to cherry-pick it:

```powershell
$appliedCommits = @()
$skippedCommits = @()

foreach ($commit in $commits) {
    $commitMsg = git show -s --format=%s $commit
    Write-Host "Applying commit: $commit - $commitMsg"
    
    # Try to cherry-pick (this will create a new commit)
    git cherry-pick $commit 2>&1 | Out-Null
    
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Conflict detected in commit: $commit"
        
        switch ($conflictStrategy) {
            'abort' {
                Write-Error "Aborting due to conflict in commit: $commit"
                git cherry-pick --abort
                git checkout $originalRef
                git branch -D $reviewBranch
                Write-Host "Cleanup complete. Please resolve conflicts or use different strategy."
                return
            }
            'skip' {
                Write-Warning "Skipping commit: $commit"
                git cherry-pick --abort
                $skippedCommits += $commit
                continue
            }
            'theirs' {
                Write-Warning "Auto-resolving with commit version (theirs)"
                git checkout --theirs .
                git add .
                git -c core.editor=true cherry-pick --continue
            }
            'ours' {
                Write-Warning "Auto-resolving with baseline version (ours)"
                git checkout --ours .
                git add .
                git -c core.editor=true cherry-pick --continue
            }
        }
    }
    
    $appliedCommits += $commit
}

Write-Host ""
Write-Host "Applied: $($appliedCommits.Count) commits"
if ($skippedCommits.Count -gt 0) {
    Write-Warning "Skipped: $($skippedCommits.Count) commits due to conflicts"
    foreach ($skipped in $skippedCommits) {
        $skippedMsg = git show -s --format=%s $skipped
        Write-Host "  - $skipped - $skippedMsg"
    }
}
```

### 5. Save Review Metadata

Create a configuration file for cleanup later:

```powershell
$config = @{
    reviewMode = "commit-list"
    commits = $commits
    appliedCommits = $appliedCommits
    skippedCommits = $skippedCommits
    baseline = $baseline
    earliestCommit = $earliestCommit
    reviewBranch = $reviewBranch
    originalRef = $originalRef
    conflictStrategy = $conflictStrategy
    timestamp = $timestamp
} | ConvertTo-Json -Depth 10

$config | Out-File -FilePath ".code-review-config.json" -Encoding UTF8
```

### 6. Provide User Instructions

After setup is complete, show the user:

```
✓ Review branch prepared successfully!

Review Branch: <reviewBranch>
Baseline: <baseline> (parent of earliest commit)
Earliest Commit: <earliestCommit>
Commits Applied: <count> (preserved as individual commits in chronological order)
Commits Skipped: <count> (if any, due to conflict strategy)

The code review pipeline is now ready to run.

To start the code review:
  Run: @REVIEW-CodeReviewOrchestrator

To cleanup after review:
  Run: @CleanupCommitReview
```

## Edge Cases

- **Earliest commit has no parent**: This is an initial commit, cannot determine baseline
- **Already on a review branch**: Warn user and ask if they want to delete it first
- **Existing .code-review-config.json**: Ask if they want to overwrite
- **Empty commit list after skips**: Abort with clear message

## Important Notes

- You are setting up for review ONLY - do not start the actual code review
- **Baseline is automatic** - Uses parent of earliest commit (no user input needed)
- **All commits are cherry-picked** - Including the earliest commit
- **Commits are preserved** - Each commit is cherry-picked individually in chronological order
- Keep the temp branch until user explicitly cleans up
- Make all status messages clear and actionable
- If anything fails, ensure proper cleanup (return to original ref, delete temp branch)

After successful setup, your job is complete. The user will invoke @REVIEW-CodeReviewOrchestrator separately to begin the actual review.