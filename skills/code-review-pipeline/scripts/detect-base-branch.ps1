# Detects whether this repo uses 'master' or 'main' as the default branch,
# creates the code-review/ output directory, and writes session-config.json
# for all downstream agents to read.
#
# Usage: Run from the root of the repository being reviewed.
# Output: code-review/session-config.json

$baseBranch = git symbolic-ref refs/remotes/origin/HEAD 2>$null
if ($baseBranch) {
    $baseBranch = $baseBranch -replace '.*/', ''
} else {
    # Fallback: check which of master/main exists
    $baseBranch = if (git show-ref --verify --quiet refs/heads/master) { 'master' } else { 'main' }
}

New-Item -ItemType Directory -Force 'code-review' | Out-Null

@{ baseBranch = $baseBranch; sessionDate = (Get-Date -Format 'yyyy-MM-dd') } |
    ConvertTo-Json |
    Set-Content 'code-review/session-config.json'

Write-Host "Base branch detected: $baseBranch"
