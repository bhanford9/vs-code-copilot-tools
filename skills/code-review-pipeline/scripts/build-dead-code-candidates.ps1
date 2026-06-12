# Scans deleted lines in the source diff for C# declaration names, then checks
# each symbol for remaining references (production vs. test-only vs. none).
#
# Outputs code-review/dead-code-candidates.md with three sections:
#   - Confirmed Dead: 0 references anywhere
#   - Test-Only References: referenced only in test files (likely dead)
#   - Still Referenced in Production: not dead — flag for auditor review
#
# Consumed by: Correctness, Maintainability, and Ripple Effect auditors.
#
# Called by build-changeset.ps1 after the source diff is generated.
# Reads code-review/session-config.json for reviewMode, baseBranch, targetCommit.
#
# Usage: & build-dead-code-candidates.ps1   (run from the repository root)

$cfg        = Get-Content 'code-review/session-config.json' | ConvertFrom-Json
$reviewMode = $cfg.reviewMode
$base       = $cfg.baseBranch
$target     = $cfg.targetCommit
$testExcludes = @(':(exclude)*Tests.cs', ':(exclude)*IntegrationTests.cs')

# Get the source-only diff (all context, deleted lines matter most)
if ($reviewMode -eq 'single-commit') {
    $diff = git show $target -- $testExcludes | Out-String
} else {
    $diff = git diff "$base...HEAD" -- $testExcludes | Out-String
}

if (-not $diff.Trim()) {
    '> No source diff found. Dead code scan skipped.' | Set-Content 'code-review/dead-code-candidates.md'
    Write-Host 'Dead code scan: no source diff.'
    return
}

# ---------------------------------------------------------------------------
# Extract C# declaration names from deleted lines.
# Pattern: line starts with '-', optional leading whitespace (up to 8 chars),
# then an access modifier, optional modifiers, a return type, then the symbol
# name, then ( or { or ;
# ---------------------------------------------------------------------------
$deletedDeclPattern = '^-\s{0,8}(?:public|internal|protected)\s+(?:(?:static|abstract|virtual|override|sealed|partial|readonly|async|new)\s+)*(?:[\w<>\[\]?,]+\s+)+(\w+)\s*[({;]'

$noiseWords = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@('if','for','while','foreach','switch','return','var','new','using',
                'class','interface','enum','record','struct','namespace',
                'get','set','add','remove','value','this','base',
                'true','false','null','void','bool','int','string',
                'double','float','decimal','long','object','Task','List',
                'IEnumerable','IReadOnlyList','IList','Dictionary'),
    [System.StringComparer]::Ordinal)

# symbol -> first source file it was deleted from (used for noise filtering)
$candidates    = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
$candidateFile = @{}

$currentDiffFile = ''
foreach ($line in ($diff -split "`n")) {
    # Track which file the current hunk belongs to
    if ($line -match '^diff --git a/(.+) b/') {
        $currentDiffFile = $matches[1]
    }

    $m = [regex]::Match($line, $deletedDeclPattern)
    if ($m.Success) {
        $name = $m.Groups[1].Value
        if ($name.Length -gt 2 -and $name -notin $noiseWords) {
            [void]$candidates.Add($name)
            if (-not $candidateFile.ContainsKey($name)) {
                $candidateFile[$name] = $currentDiffFile
            }
        }
    }
}

# ---------------------------------------------------------------------------
# Noise filter: if the source file still exists AND still contains the symbol,
# the declaration was modified, not deleted — remove it from candidates.
# Symbols from entirely-deleted files are always kept.
# ---------------------------------------------------------------------------
$filteredCandidates = [System.Collections.Generic.List[string]]::new()
foreach ($name in $candidates) {
    $srcFile = $candidateFile[$name]
    if ($srcFile -and (Test-Path $srcFile)) {
        $stillPresent = git grep -l "\b$name\b" -- $srcFile 2>$null
        if ($stillPresent) {
            Write-Host "  Skipping '$name' — still present in $srcFile (modified, not deleted)"
            continue
        }
    }
    [void]$filteredCandidates.Add($name)
}
$candidates = $filteredCandidates

if ($candidates.Count -eq 0) {
    '> No deleted C# declarations detected in diff. Dead code scan found no candidates.' |
        Set-Content 'code-review/dead-code-candidates.md'
    Write-Host 'Dead code scan: no candidates found.'
    return
}

Write-Host "Dead code scan: $($candidates.Count) candidate symbol(s) — checking references..."

# ---------------------------------------------------------------------------
# For each candidate, check remaining references split by production vs test.
# git grep -l = file names only (no line content), fast for existence check.
# ---------------------------------------------------------------------------
$results = @()
foreach ($symbol in ($candidates | Sort-Object)) {
    $allHits        = @(git grep -l "\b$symbol\b" -- '*.cs' 2>$null)
    $productionHits = @($allHits | Where-Object { $_ -notmatch 'Tests\.cs$' -and $_ -notmatch 'IntegrationTests\.cs$' })
    $testHits       = @($allHits | Where-Object { $_ -match 'Tests\.cs$' -or  $_ -match 'IntegrationTests\.cs$' })

    $results += [PSCustomObject]@{
        Symbol          = $symbol
        ProductionCount = $productionHits.Count
        TestCount       = $testHits.Count
        ProductionFiles = $productionHits
    }
}

# ---------------------------------------------------------------------------
# Write output
# ---------------------------------------------------------------------------
$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('# Dead Code Candidates')
[void]$sb.AppendLine()
[void]$sb.AppendLine('> Auto-generated: C# declarations deleted from production source, scanned for remaining references.')
[void]$sb.AppendLine('> Consumed by: Correctness, Maintainability, and Ripple Effect auditors.')
[void]$sb.AppendLine()

$confirmed = @($results | Where-Object { $_.ProductionCount -eq 0 -and $_.TestCount -eq 0 })
$testOnly  = @($results | Where-Object { $_.ProductionCount -eq 0 -and $_.TestCount -gt 0 })
$hasProds  = @($results | Where-Object { $_.ProductionCount -gt 0 })

if ($confirmed.Count -gt 0) {
    [void]$sb.AppendLine('## Confirmed Dead (0 references anywhere)')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('These symbols are safe to remove from any remaining DI registrations, mocks, or companion files.')
    [void]$sb.AppendLine()
    foreach ($r in $confirmed) {
        [void]$sb.AppendLine("- ``$($r.Symbol)``")
    }
    [void]$sb.AppendLine()
}

if ($testOnly.Count -gt 0) {
    [void]$sb.AppendLine('## Test-Only References (likely dead — verify test fixtures can be removed)')
    [void]$sb.AppendLine()
    foreach ($r in $testOnly) {
        [void]$sb.AppendLine("- ``$($r.Symbol)`` — $($r.TestCount) test file(s)")
    }
    [void]$sb.AppendLine()
}

if ($hasProds.Count -gt 0) {
    [void]$sb.AppendLine('## Still Referenced in Production (verify these deletions were intentional)')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('> These symbols were removed from the changed files but still appear in other production files.')
    [void]$sb.AppendLine('> Each entry may represent an incomplete deletion or a ripple effect miss.')
    [void]$sb.AppendLine()
    foreach ($r in $hasProds) {
        [void]$sb.AppendLine("### ``$($r.Symbol)`` — $($r.ProductionCount) production file(s)")
        foreach ($f in $r.ProductionFiles) {
            [void]$sb.AppendLine("- $f")
        }
        [void]$sb.AppendLine()
    }
}

$sb.ToString() | Set-Content 'code-review/dead-code-candidates.md'
Write-Host "Dead code candidates written to code-review/dead-code-candidates.md ($($confirmed.Count) confirmed dead, $($testOnly.Count) test-only, $($hasProds.Count) still in production)"
