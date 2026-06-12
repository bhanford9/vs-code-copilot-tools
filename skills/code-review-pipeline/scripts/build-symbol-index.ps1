# Extracts changed public symbols from a list of changed .cs files, then runs git grep
# across the entire Source tree to build a reference index: symbol → file:line:content.
#
# Two modes:
#   Called mode: & build-symbol-index.ps1 -ChangedFiles $changedFiles
#     Returns the index as a string (captured by caller).
#   Standalone mode: & build-symbol-index.ps1  (no args)
#     Reads code-review/session-config.json to compute ChangedFiles itself,
#     writes directly to code-review/symbol-index.md.
#     Used by the Ripple Effect auditor when the file was not pre-generated.

param(
    [string[]]$ChangedFiles = @()
)

$standaloneMode = (-not $ChangedFiles -or $ChangedFiles.Count -eq 0)

if ($standaloneMode) {
    if (-not (Test-Path 'code-review/session-config.json')) {
        Write-Error 'No -ChangedFiles provided and no code-review/session-config.json found.'
        return
    }
    $cfg        = Get-Content 'code-review/session-config.json' | ConvertFrom-Json
    $reviewMode = $cfg.reviewMode
    $base       = $cfg.baseBranch
    $target     = $cfg.targetCommit
    $testExcludes = @(':(exclude)*Tests.cs', ':(exclude)*IntegrationTests.cs')

    if ($reviewMode -eq 'single-commit') {
        $ChangedFiles = @(git show $target --name-only --format='' |
            Where-Object { $_ -match '\.cs$' -and $_ -notmatch 'Tests\.cs$' } |
            Where-Object { Test-Path $_ })
    } else {
        $ChangedFiles = @(git diff "$base...HEAD" --name-only |
            Where-Object { $_ -match '\.cs$' -and $_ -notmatch 'Tests\.cs$' } |
            Where-Object { Test-Path $_ })
    }

    if (-not $ChangedFiles -or $ChangedFiles.Count -eq 0) {
        '> No changed source files detected. Symbol index skipped.' | Set-Content 'code-review/symbol-index.md'
        Write-Host 'Symbol index: no changed files detected.'
        return
    }
    Write-Host "Symbol index: standalone mode — $($ChangedFiles.Count) changed source files"
}

# ---------------------------------------------------------------------------
# Step 1: Extract public symbol names from the changed files using regex.
# We look for: public/internal class, interface, enum, record, struct, method
# signatures. We use a heuristic regex — not a full parser, but covers 95% of
# cases for C#. Only captures declared names (not references).
# ---------------------------------------------------------------------------
$symbolPattern = '(?:public|internal|protected)\s+(?:(?:static|abstract|virtual|override|sealed|partial|readonly|async)\s+)*(?:class|interface|enum|record|struct|void|[\w<>\[\]]+)\s+(\w+)\s*[<({]'

$symbols = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)

foreach ($file in $ChangedFiles) {
    if (-not (Test-Path $file)) { continue }
    $content = Get-Content $file -Raw
    $matches  = [regex]::Matches($content, $symbolPattern)
    foreach ($m in $matches) {
        $name = $m.Groups[1].Value
        # Skip noise: common keywords captured by the heuristic
        if ($name -notin @('if','for','while','foreach','switch','return','var','new','using','async','await','static','override','virtual','sealed','partial')) {
            [void]$symbols.Add($name)
        }
    }
}

if ($symbols.Count -eq 0) {
    return '> No public symbols extracted from changed files. Symbol index skipped.'
}

# Cap at 60 symbols to keep the alternation regex performant and the output readable.
# Prefer interface names (I-prefix) and class names over method names.
$orderedSymbols = @(
    ($symbols | Where-Object { $_ -match '^I[A-Z]' } | Sort-Object)   # interfaces first
    ($symbols | Where-Object { $_ -notmatch '^I[A-Z]' } | Sort-Object) # then rest
) | Select-Object -First 60

# ---------------------------------------------------------------------------
# Step 2: Single git grep call with an alternation pattern across all tracked
# *.cs files. git grep is ~180x faster than PowerShell Select-String on large
# repos (0.6s vs 93s for 10k files). Requires git to be available, which is
# already a pipeline prerequisite.
# ---------------------------------------------------------------------------

# Build ERE alternation pattern: \bSymbol1\b|\bSymbol2\b|...
$grepPattern = ($orderedSymbols | ForEach-Object { "\b$_\b" }) -join '|'

# git grep -n = include line numbers, -E = extended regex, output: file:line:content
$rawHits = git grep -n -E $grepPattern -- '*.cs' 2>$null

$repoRoot = (Get-Location).Path
$compiledRegex = [regex]::new('\b(' + (($orderedSymbols | ForEach-Object { [regex]::Escape($_) }) -join '|') + ')\b',
                              [System.Text.RegularExpressions.RegexOptions]::Compiled)

# Parse git grep output lines: "path/to/file.cs:42:    line content"
# Group by symbol using one compiled .NET regex match per line.
$grouped = @{}
foreach ($raw in $rawHits) {
    # Split on first two colons only (path may contain no colons on Windows git output)
    $colonIdx1 = $raw.IndexOf(':')
    if ($colonIdx1 -lt 0) { continue }
    $colonIdx2 = $raw.IndexOf(':', $colonIdx1 + 1)
    if ($colonIdx2 -lt 0) { continue }

    $filePath   = $raw.Substring(0, $colonIdx1)
    $lineNumber = $raw.Substring($colonIdx1 + 1, $colonIdx2 - $colonIdx1 - 1)
    $lineContent = $raw.Substring($colonIdx2 + 1)

    $m = $compiledRegex.Match($lineContent)
    while ($m.Success) {
        $sym = $m.Groups[1].Value
        if (-not $grouped.ContainsKey($sym)) {
            $grouped[$sym] = [System.Collections.Generic.List[object]]::new()
        }
        $grouped[$sym].Add([PSCustomObject]@{ Path = $filePath; LineNumber = $lineNumber; Line = $lineContent })
        $m = $m.NextMatch()
    }
}

$sb = [System.Text.StringBuilder]::new()
if ($symbols.Count -gt 60) {
    [void]$sb.AppendLine("> **Note**: $($symbols.Count) symbols extracted; index limited to first 60 (interfaces prioritized). Remaining symbols can be searched on demand.")
    [void]$sb.AppendLine()
}

foreach ($symbol in $orderedSymbols) {
    if (-not $grouped.ContainsKey($symbol)) { continue }
    $hits = $grouped[$symbol] | Select-Object -First 30  # cap at 30 hits per symbol

    [void]$sb.AppendLine("### ``$symbol``")
    [void]$sb.AppendLine()
    [void]$sb.AppendLine('| File | Line | Content |')
    [void]$sb.AppendLine('|------|------|---------|')

    foreach ($hit in $hits) {
        $relPath     = $hit.Path -replace [regex]::Escape($repoRoot + '\'), '' -replace '\\', '/'
        $lineContent = $hit.Line.Trim() -replace '\|', '\|'
        if ($lineContent.Length -gt 120) { $lineContent = $lineContent.Substring(0, 117) + '...' }
        [void]$sb.AppendLine("| $relPath | $($hit.LineNumber) | ``$lineContent`` |")
    }
    [void]$sb.AppendLine()
}

if ($standaloneMode) {
    $sb.ToString() | Set-Content 'code-review/symbol-index.md'
    Write-Host "Symbol index written to code-review/symbol-index.md ($($orderedSymbols.Count) symbols)"
} else {
    return $sb.ToString()
}
