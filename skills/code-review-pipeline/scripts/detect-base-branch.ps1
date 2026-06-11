# Detects whether this repo uses 'master' or 'main' as the default branch,
# creates the code-review/ output directory, and writes session-config.json
# for all downstream agents to read.
#
# Usage: Run from the root of the repository being reviewed.
#   Optional: -TargetCommit <sha>  — when reviewing a single already-merged commit
# Output: code-review/session-config.json

param(
    [string]$TargetCommit = ''
)

$baseBranch = git symbolic-ref refs/remotes/origin/HEAD 2>$null
if ($baseBranch) {
    $baseBranch = $baseBranch -replace '.*/', ''
} else {
    # Fallback: check which of master/main exists
    $baseBranch = if (git show-ref --verify --quiet refs/heads/master) { 'master' } else { 'main' }
}

# Detect security surface: scan changed file paths for web/auth/input/external patterns
$securitySurface = $false
if ($TargetCommit) {
    $changedFiles = git show $TargetCommit --name-only --format='' | Where-Object { $_ -ne '' }
} else {
    $changedFiles = git diff "$baseBranch...HEAD" --name-only | Where-Object { $_ -ne '' }
}
$securityPatterns = @(
    'Controller', 'Middleware', 'Authorize', 'Authentication', 'Authorization',
    'HttpClient', 'WebClient', 'RestClient', 'ApiClient',
    'Password', 'Secret', 'Token', 'Credential', 'Encrypt', 'Hash',
    'Sanitize', 'Validate', 'InputModel', 'RequestModel',
    'SqlCommand', 'DbContext', 'Repository'
)
foreach ($file in $changedFiles) {
    foreach ($pattern in $securityPatterns) {
        if ($file -match $pattern) { $securitySurface = $true; break }
    }
    if ($securitySurface) { break }
}

New-Item -ItemType Directory -Force 'code-review' | Out-Null

$config = @{
    baseBranch       = $baseBranch
    sessionDate      = (Get-Date -Format 'yyyy-MM-dd')
    targetCommit     = $TargetCommit
    securitySurface  = $securitySurface
}
$config | ConvertTo-Json | Set-Content 'code-review/session-config.json'

Write-Host "Base branch detected: $baseBranch"
if ($TargetCommit) { Write-Host "Target commit: $TargetCommit" }
Write-Host "Security surface: $securitySurface"
