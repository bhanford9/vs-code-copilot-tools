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

# Detect security surface: scan changed file paths for web/auth/input/external patterns.
# Test files (*Tests.cs) are excluded — they inherit production class names (e.g.,
# RepositoryTests.cs) and cause false positives. Artifact fixtures are also excluded.
$securitySurface = $false
if ($TargetCommit) {
    $changedFiles = git show $TargetCommit --name-only --format='' | Where-Object { $_ -ne '' }
} else {
    $changedFiles = git diff "$baseBranch...HEAD" --name-only | Where-Object { $_ -ne '' }
}
# Load workspace-local exclusions (codebase-specific extensions/paths).
# Convention: workspace provides .github/scripts/review-exclusions.json
# Schema: { "extensionExcludes": ["*.fja", "*.std"], "pathExcludes": ["**/IntegrationTests/**"] }
$wsExclusions = @{ extensionExcludes = @(); pathExcludes = @() }
$wsExclusionsFile = '.github/scripts/review-exclusions.json'
if (Test-Path $wsExclusionsFile) {
    $wsExclusions = Get-Content $wsExclusionsFile | ConvertFrom-Json
    Write-Host "Loaded workspace exclusions from $wsExclusionsFile"
}

# Build exclusion regexes from the workspace config
$extPatterns  = $wsExclusions.extensionExcludes | ForEach-Object { [regex]::Escape($_.TrimStart('*')) + '$' }
$pathPatterns = $wsExclusions.pathExcludes     | ForEach-Object { $_ -replace '\*\*/', '[/\\\\]' -replace '\*\*', '.*' -replace '/', '[/\\\\]' }

$reviewableFiles = $changedFiles | Where-Object {
    $f = $_
    if ($f -match 'Tests\.cs$') { return $false }  # Test files always excluded — inherit prod class names
    foreach ($ext  in $extPatterns)  { if ($f -match $ext)  { return $false } }
    foreach ($path in $pathPatterns) { if ($f -match $path) { return $false } }
    return $true
}
$securityPatterns = @(
    'Controller', 'Middleware', 'Authorize', 'Authentication', 'Authorization',
    'HttpClient', 'WebClient', 'RestClient', 'ApiClient',
    'Password', 'Secret', 'Token', 'Credential', 'Encrypt', 'Hash',
    'Sanitize', 'Validate', 'InputModel', 'RequestModel',
    'SqlCommand', 'DbContext', 'Repository'
)
foreach ($file in $reviewableFiles) {
    $fileName = Split-Path $file -Leaf   # match against filename only, not directory segments
    foreach ($pattern in $securityPatterns) {
        if ($fileName -match $pattern) { $securitySurface = $true; break }
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
