# clean-review-artifacts.ps1
#
# Removes stale artifacts from a previous code review run.
# Called by REVIEW-CodeReviewOrchestrator at the start of each new review.
# Preserves session-config.json (written by detect-base-branch.ps1 before this runs).

Remove-Item 'code-review\*.md'   -ErrorAction SilentlyContinue
Remove-Item 'code-review\*.json' -Exclude 'session-config.json' -ErrorAction SilentlyContinue
Remove-Item 'code-review\slices\*' -ErrorAction SilentlyContinue

Write-Host 'Stale review artifacts cleaned.'
