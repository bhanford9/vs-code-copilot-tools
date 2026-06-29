# build-prelim-classify.ps1
#
# Reads code-review/changeset-full.md and produces two outputs:
#   code-review/prelim-classify.json      — per-file auditor flags based on Section B grep signals
#   code-review/changeset-sections-AB.md  — Sections A+B only (deterministic Dispatcher read artifact)
#
# Called automatically by build-changeset.ps1 after writing changeset-full.md.
# The Dispatcher reads these two bounded files instead of the full changeset.

param(
    [string]$ChangesetPath = 'code-review/changeset-full.md'
)

if (-not (Test-Path $ChangesetPath)) {
    Write-Error "Changeset not found: $ChangesetPath"
    exit 1
}

$lines = Get-Content $ChangesetPath

# ---------------------------------------------------------------------------
# Write changeset-sections-AB.md
# Stop before the first Section C CHUNK marker (or include all if diff-only mode)
# ---------------------------------------------------------------------------
$sectionCStartLine = -1
for ($i = 0; $i -lt $lines.Count; $i++) {
    if ($lines[$i] -match '^<!-- CHUNK file=".+" section="C" -->') {
        $sectionCStartLine = $i
        break
    }
}

if ($sectionCStartLine -gt 0) {
    $abLines = $lines[0..($sectionCStartLine - 1)]
} else {
    # diff-only mode — no Section C chunks; all lines are A+B
    $abLines = $lines
}

$abLines | Set-Content 'code-review/changeset-sections-AB.md'
Write-Host "Sections A+B written to code-review/changeset-sections-AB.md ($($abLines.Count) lines of $($lines.Count) total)"

# ---------------------------------------------------------------------------
# Parse Section B CHUNK blocks and classify files by grep signals
# ---------------------------------------------------------------------------
$signalPatterns = @{
    performance   = 'for\s*\(|foreach\s*\(|while\s*\(|\bawait\s|\bStream\b|\.Read[^e]|\bHttpClient\b'
    extensibility = '(?m)^\s*(public|internal)\s+(interface|abstract\s+class)|services\.Add|\.RegisterType|builder\.Register'
    security      = '\[Authorize\b|\bPassword\b|\bEncrypt\b|\bJWT\b|\.Input\b|\bSqlCommand\b|\.Query\b'
}

# Extract Section B CHUNK blocks using a manual line-by-line scan
$fileResults      = [ordered]@{}
$allChangedFiles  = [System.Collections.Generic.List[string]]::new()

$inChunk     = $false
$currentFile = $null
$chunkLines  = [System.Text.StringBuilder]::new()

foreach ($line in $lines) {
    if ($line -match '^<!-- CHUNK file="(?<file>[^"]+)" section="B" -->') {
        $inChunk     = $true
        $currentFile = $matches['file']
        $null = $chunkLines.Clear()
        continue
    }
    if ($line -eq '<!-- /CHUNK -->' -and $inChunk) {
        $inChunk = $false
        if ($currentFile) {
            $content = $chunkLines.ToString()
            $allChangedFiles.Add($currentFile)

            $flags = [ordered]@{
                performance        = $false
                extensibility      = $false
                security           = $false
                sectionC_candidate = $false  # always false from script — LLM decides in Step 3
            }

            foreach ($key in $signalPatterns.Keys) {
                if ($content -match $signalPatterns[$key]) {
                    $flags[$key] = $true
                }
            }

            $fileResults[$currentFile] = $flags
        }
        $currentFile = $null
        continue
    }
    if ($line -match '^<!-- CHUNK file=".+" section="C" -->') {
        # Reached Section C — stop scanning
        break
    }
    if ($inChunk) {
        [void]$chunkLines.AppendLine($line)
    }
}

$output = [ordered]@{
    files             = $fileResults
    all_changed_files = @($allChangedFiles)
}

$output | ConvertTo-Json -Depth 5 | Set-Content 'code-review/prelim-classify.json'
Write-Host "Prelim classification written to code-review/prelim-classify.json ($($fileResults.Count) files classified)"
