# Reads code-review/session-config.json and writes:
#   code-review/changeset.md            — stat-level summary (unchanged format, backward compat)
#   code-review/changeset-full.md       — enriched: commit messages, source-only diff hunks, full
#                                         source (size-gated), symbol index pointer, test file index
#   code-review/test-diffs.md           — test file diffs only (consumed by Batch A auditors)
#   code-review/dead-code-candidates.md — deleted declarations with remaining reference counts
#   code-review/captive-deps.md         — captive dependency findings, IF .github/scripts/check-captive-dependencies.ps1 exists
#
# Note: code-review/symbol-index.md is generated on demand by the Ripple Effect auditor
#       (via build-symbol-index.ps1 standalone mode — no longer pre-generated here).
#
# Calls build-dead-code-candidates.ps1 and build-test-index.ps1.
# Optionally calls .github/scripts/check-captive-dependencies.ps1 (workspace-local, stack-specific).
#
# Usage: Run from the root of the repository being reviewed, after
#        detect-base-branch.ps1 has written session-config.json.

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$cfg       = Get-Content 'code-review/session-config.json' | ConvertFrom-Json
$base      = $cfg.baseBranch
$target    = $cfg.targetCommit

# ---------------------------------------------------------------------------
# Determine review mode: branch diff vs. single-commit fallback
# ---------------------------------------------------------------------------
$reviewMode = 'branch'
$commits    = git log "$base..HEAD" --oneline | Out-String

if (-not $commits.Trim()) {
    if ($target) {
        $reviewMode = 'single-commit'
        Write-Host "Branch diff is empty. Falling back to single-commit mode: $target"
    } else {
        Write-Warning "Branch diff is empty and no targetCommit in session-config.json. Changeset will be empty."
    }
}

# Write reviewMode back to session-config so auditors know the scope
$cfgObj = Get-Content 'code-review/session-config.json' | ConvertFrom-Json
$cfgObj | Add-Member -NotePropertyName 'reviewMode' -NotePropertyValue $reviewMode -Force
$cfgObj | ConvertTo-Json | Set-Content 'code-review/session-config.json'

# ---------------------------------------------------------------------------
# Build stat-level changeset.md (unchanged format)
# ---------------------------------------------------------------------------
if ($reviewMode -eq 'single-commit') {
    $commits = git show $target --oneline -s | Out-String
    $stat    = git show $target --stat | Out-String
    $status  = ''
} else {
    $stat   = git diff "$base...HEAD" --stat | Out-String
    $status = git status --short | Out-String
}

"## Commits`n$commits`n## Files Changed`n$stat`n## Uncommitted`n$status" |
    Set-Content 'code-review/changeset.md'

Write-Host "Changeset written to code-review/changeset.md"

# ---------------------------------------------------------------------------
# Adaptive unified diff context: scale down for large changesets to keep
# changeset-full.md token-efficient for the sequential auditors.
# ---------------------------------------------------------------------------
if ($reviewMode -eq 'single-commit') {
    $allChangedFileCount = @(git show $target --name-only --format='' | Where-Object { $_ }).Count
} else {
    $allChangedFileCount = @(git diff "$base...HEAD" --name-only | Where-Object { $_ }).Count
}
$unifiedContext = if ($allChangedFileCount -gt 50) { 3 } else { 10 }
Write-Host "Adaptive diff context: --unified=$unifiedContext ($allChangedFileCount changed files)"

# ---------------------------------------------------------------------------
# Build changeset-full.md
# ---------------------------------------------------------------------------
$out = [System.Text.StringBuilder]::new()

# --- Section A: Commit messages + bodies ---
[void]$out.AppendLine('# Changeset — Full Context')
[void]$out.AppendLine()
[void]$out.AppendLine('## Section A — Commit Messages')
[void]$out.AppendLine()
if ($reviewMode -eq 'single-commit') {
    $log = git show $target --format='%H %s%n%b' -s | Out-String
} else {
    $log = git log "$base..HEAD" --format='%H %s%n%b' | Out-String
}
[void]$out.AppendLine($log.Trim())

# --- Section B: Source-only diff hunks (--unified=10, test files excluded) ---
[void]$out.AppendLine()
[void]$out.AppendLine("## Section B — Diff Hunks: Source Files ($unifiedContext lines context, test files excluded)")
[void]$out.AppendLine()
$testExcludes = @(':(exclude)*Tests.cs', ':(exclude)*IntegrationTests.cs')
if ($reviewMode -eq 'single-commit') {
    $diff = git show $target --unified=$unifiedContext -- $testExcludes | Out-String
} else {
    $diff = git diff "$base...HEAD" --unified=$unifiedContext -- $testExcludes | Out-String
}
[void]$out.AppendLine('```diff')
[void]$out.AppendLine($diff.Trim())
[void]$out.AppendLine('```')
[void]$out.AppendLine()
[void]$out.AppendLine('> Test file diffs: see `code-review/test-diffs.md`')

# --- Test diffs: written to separate file so only Batch A auditors pay for them ---
$testDiffsOut = [System.Text.StringBuilder]::new()
[void]$testDiffsOut.AppendLine('# Test File Diffs')
[void]$testDiffsOut.AppendLine()
[void]$testDiffsOut.AppendLine('> Consumed by: Unit Test Coverage and Testability auditors only.')
[void]$testDiffsOut.AppendLine()
if ($reviewMode -eq 'single-commit') {
    $testDiff = git show $target --unified=$unifiedContext -- '*Tests.cs' '*IntegrationTests.cs' | Out-String
} else {
    $testDiff = git diff "$base...HEAD" --unified=$unifiedContext -- '*Tests.cs' '*IntegrationTests.cs' | Out-String
}
if ($testDiff.Trim()) {
    [void]$testDiffsOut.AppendLine('```diff')
    [void]$testDiffsOut.AppendLine($testDiff.Trim())
    [void]$testDiffsOut.AppendLine('```')
} else {
    [void]$testDiffsOut.AppendLine('> No test file changes in this changeset.')
}
$testDiffsOut.ToString() | Set-Content 'code-review/test-diffs.md'
Write-Host 'Test diffs written to code-review/test-diffs.md'

# --- Section C: Full source (size-gated at ≤20 non-test source files) ---
[void]$out.AppendLine()
[void]$out.AppendLine('## Section C — Full Source Content')
[void]$out.AppendLine()

if ($reviewMode -eq 'single-commit') {
    $changedFiles = git show $target --name-only --format='' | Where-Object { $_ -match '\.cs$' -and $_ -notmatch 'Tests\.cs$' }
} else {
    $changedFiles = git diff "$base...HEAD" --name-only | Where-Object { $_ -match '\.cs$' -and $_ -notmatch 'Tests\.cs$' }
}
$changedFiles = @($changedFiles | Where-Object { Test-Path $_ })

# Write Section C metadata to session-config for parallel auditors (avoids opening changeset-full.md)
$sectionCMode = if ($changedFiles.Count -le 20) { 'full-source' } else { 'diff-only' }
$cfgObj2 = Get-Content 'code-review/session-config.json' | ConvertFrom-Json
$cfgObj2 | Add-Member -NotePropertyName 'sourceFileCount' -NotePropertyValue $changedFiles.Count -Force
$cfgObj2 | Add-Member -NotePropertyName 'sectionCMode'    -NotePropertyValue $sectionCMode      -Force
$cfgObj2 | ConvertTo-Json | Set-Content 'code-review/session-config.json'

if ($changedFiles.Count -le 20) {
    [void]$out.AppendLine("> **Mode: full-source** - $($changedFiles.Count) non-test source files (threshold: 20). Complete current file content embedded below.")
    [void]$out.AppendLine()
    foreach ($f in $changedFiles) {
        [void]$out.AppendLine("### $f")
        [void]$out.AppendLine('```csharp')
        [void]$out.AppendLine((Get-Content $f -Raw).Trim())
        [void]$out.AppendLine('```')
        [void]$out.AppendLine()
    }
} else {
    [void]$out.AppendLine("> **Mode: diff-only** - $($changedFiles.Count) non-test source files (threshold: 20 exceeded). Full source omitted. Use Section B diff hunks and Section D symbol reference index for navigation.")
}

# --- Section D: Symbol reference index — generated on demand by Ripple Effect auditor ---
[void]$out.AppendLine()
[void]$out.AppendLine('## Section D — Symbol Reference Index')
[void]$out.AppendLine()
[void]$out.AppendLine('> Generated on demand by the Ripple Effect auditor. If `code-review/symbol-index.md` does not exist,')
[void]$out.AppendLine('> the auditor runs `build-symbol-index.ps1` (no args, reads session-config.json) from the repo root.')

# --- Section E: Test file index ---
$testIndex = & "$scriptDir\build-test-index.ps1" -ChangedFiles $changedFiles
[void]$out.AppendLine()
[void]$out.AppendLine('## Section E — Test File Index')
[void]$out.AppendLine()
[void]$out.AppendLine($testIndex)

$out.ToString() | Set-Content 'code-review/changeset-full.md'
Write-Host "Full changeset written to code-review/changeset-full.md"

# --- Dead code candidates: deleted declarations with remaining reference counts ---
& "$scriptDir\build-dead-code-candidates.ps1"

# --- Workspace-local captive dependency check (stack-specific, optional) ---
# Convention: workspace provides .github/scripts/check-captive-dependencies.ps1
# Contract:   script must write findings to code-review/captive-deps.md
# To replace: swap the script file; keep the output path the same.
$captiveDepsScript = '.github/scripts/check-captive-dependencies.ps1'
if (Test-Path $captiveDepsScript) {
    Write-Host 'Running workspace-local captive dependency check...'
    & powershell -File $captiveDepsScript
    Write-Host 'Captive dependency check written to code-review/captive-deps.md'
} else {
    Write-Host "Skipping captive dependency check (no $captiveDepsScript found)"
}
