---
name: cleanup-commit-review
description: Restore the repository to its original state and remove temporary branches after a commit-based code review
agent: Implementation
---

You are cleaning up after a commit-based code review. Your task is to restore the repository to its original state and remove temporary branches and configuration files.

## Your Workflow

### 1. Check for Review Configuration

Look for `.code-review-config.json` in the current directory:

```powershell
if (-not (Test-Path ".code-review-config.json")) {
    Write-Error "No review configuration found. Nothing to clean up."
    Write-Host "If you manually created a review branch, you'll need to clean it up manually."
    return
}
```

### 2. Load Configuration

Read the review metadata:

```powershell
$config = Get-Content ".code-review-config.json" | ConvertFrom-Json

Write-Host "Review Configuration:"
Write-Host "  Review Branch: $($config.reviewBranch)"
Write-Host "  Original Ref: $($config.originalRef)"
Write-Host "  Baseline: $($config.baseline)"
Write-Host "  Commits Applied: $($config.appliedCommits.Count)"
if ($config.skippedCommits.Count -gt 0) {
    Write-Host "  Commits Skipped: $($config.skippedCommits.Count)"
}
Write-Host ""
```

### 3. Verify Current State

Check if still on the review branch:

```powershell
$currentBranch = git rev-parse --abbrev-ref HEAD

if ($currentBranch -eq $config.reviewBranch) {
    Write-Host "Currently on review branch. Switching back to original ref..."
} else {
    Write-Host "Already on different branch: $currentBranch"
}
```

### 4. Return to Original Reference

Switch back to the original branch/commit:

```powershell
Write-Host "Checking out: $($config.originalRef)"
git checkout $config.originalRef

if ($LASTEXITCODE -ne 0) {
    Write-Error "Failed to checkout original ref: $($config.originalRef)"
    Write-Host "You may need to manually checkout your original branch."
    return
}

Write-Host "✓ Returned to: $($config.originalRef)"
```

### 5. Delete Review Branch

Remove the temporary review branch:

```powershell
Write-Host "Deleting review branch: $($config.reviewBranch)"
git branch -D $config.reviewBranch

if ($LASTEXITCODE -ne 0) {
    Write-Warning "Failed to delete branch: $($config.reviewBranch)"
    Write-Host "You may need to manually delete it with: git branch -D $($config.reviewBranch)"
} else {
    Write-Host "✓ Deleted branch: $($config.reviewBranch)"
}
```

### 6. Remove Configuration File

Delete the review metadata:

```powershell
Remove-Item ".code-review-config.json"
Write-Host "✓ Removed configuration file"
```

### 7. Optionally Preserve Review Reports

Ask user if they want to keep or delete the review reports:

```
The code review reports are in the /code-review/ directory.

Do you want to:
1. Keep the reports (default)
2. Delete all review reports

Choice (1-2):
```

If user chooses to delete:

```powershell
if (Test-Path "/code-review/") {
    Remove-Item -Path "/code-review/*" -Force
    Write-Host "✓ Deleted all review reports"
}
```

### 8. Summary

Provide final status:

```
✓ Cleanup complete!

  - Returned to: <original-ref>
  - Deleted branch: <review-branch>
  - Removed configuration file
  - Review reports: [kept/deleted]

Repository is now back to its original state.
```

## Edge Cases to Handle

- **Configuration file missing**: Inform user and exit gracefully
- **Original ref doesn't exist anymore**: Ask user where to go instead
- **Review branch already deleted**: Note and continue
- **Uncommitted changes exist**: Warn user they may lose work
- **Can't switch branches**: Provide manual instructions

## Important Notes

- Always err on the side of caution - don't force destructive operations
- Provide clear manual cleanup instructions if automated cleanup fails
- Preserve review reports by default (they're valuable artifacts)
- Make status messages clear about what was done vs what failed
