# Reads code-review/session-config.json and writes a changeset summary to
# code-review/changeset.md for all downstream auditor agents to consume.
#
# Usage: Run from the root of the repository being reviewed, after
#        detect-base-branch.ps1 has written session-config.json.
# Output: code-review/changeset.md

$cfg     = Get-Content 'code-review/session-config.json' | ConvertFrom-Json
$base    = $cfg.baseBranch
$commits = git log "$base..HEAD" --oneline | Out-String
$stat    = git diff "$base...HEAD" --stat | Out-String
$status  = git status --short | Out-String

"## Commits`n$commits`n## Files Changed`n$stat`n## Uncommitted`n$status" |
    Set-Content 'code-review/changeset.md'

Write-Host "Changeset written to code-review/changeset.md"
