# build-slices.ps1
#
# Reads code-review/dispatch-manifest.json and assembles per-auditor changeset slice files.
# Measures each slice ratio and writes code-review/auditor-input-index.md.
#
# Called by REVIEW-ChangesetDispatcher (via its SKILL.md Step 5) after writing dispatch-manifest.json.
# The index includes a ## Shared Context placeholder that the Correctness Auditor fills in Stage 3.

param(
    [string] $ManifestPath  = 'code-review/dispatch-manifest.json',
    [string] $ChangesetPath = 'code-review/changeset-full.md',
    [string] $ConfigPath    = 'code-review/session-config.json',
    [decimal]$Threshold     = 0.75
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

foreach ($req in @($ManifestPath, $ChangesetPath, $ConfigPath)) {
    if (-not (Test-Path $req)) { Write-Error "Required file not found: $req"; exit 1 }
}

$manifest  = Get-Content $ManifestPath | ConvertFrom-Json
$content   = Get-Content $ChangesetPath -Raw

# ---------------------------------------------------------------------------
# Extract all CHUNK blocks and named SECTION blocks from changeset-full.md
# ---------------------------------------------------------------------------
$chunks = @{}   # key: "file|section" => content string

$inChunk     = $false
$currentKey  = $null
$chunkBuffer = [System.Text.StringBuilder]::new()

foreach ($line in (Get-Content $ChangesetPath)) {
    if ($line -match '^<!-- CHUNK file="(?<file>[^"]+)" section="(?<sec>[^"]+)" -->') {
        $inChunk    = $true
        $currentKey = "$($matches['file'])|$($matches['sec'])"
        $null = $chunkBuffer.Clear()
        continue
    }
    if ($line -eq '<!-- /CHUNK -->' -and $inChunk) {
        $inChunk = $false
        $chunks[$currentKey] = $chunkBuffer.ToString().TrimEnd()
        $currentKey = $null
        continue
    }
    if ($inChunk) {
        [void]$chunkBuffer.AppendLine($line)
    }
}

# Extract named sections (D, E)
function Get-NamedSection([string]$sectionName) {
    $pattern = "<!-- SECTION:$sectionName -->\s*(?<content>.*?)<!-- /SECTION:$sectionName -->"
    $m = [regex]::Match($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)
    if ($m.Success) { return $m.Groups['content'].Value.Trim() }
    return $null
}

$sectionD = Get-NamedSection 'D'
$sectionE = Get-NamedSection 'E'

# Extract Section A (everything before first Section B header or CHUNK)
$sectionA = ''
if ($content -match '(?s)## Section A.*?\n(.*?)(?=## Section B|<!-- CHUNK)') {
    $sectionA = $matches[1].Trim()
}

$null = New-Item -ItemType Directory -Path 'code-review/slices' -Force

# ---------------------------------------------------------------------------
# Per-auditor Section C line cap
# Auditors that review code structure/quality see the first N lines of large
# files — enough to assess class shape, fields, and key method signatures
# without reading full implementation bodies.  0 = no cap.
# Performance and ripple-effect are uncapped: they need full implementation
# details to spot allocation patterns and symbol reference chains.
# ---------------------------------------------------------------------------
$sectionCCaps = @{
    'performance'         = 0      # needs full implementation for allocation/loop analysis
    'ripple-effect'       = 0      # needs full source for symbol call-chain tracing
    'structural-patterns' = 300    # class shape + first key methods is sufficient
    'maintainability'     = 300    # DRY/complexity/naming visible within first 300 lines
    'unit-test-coverage'  = 300    # rarely receives Section C; cap is a safety net
    'testability'         = 300    # constructor + DI seams visible in first 300 lines
    'extensibility'       = 300    # interface declarations + constructor are compact
    'security'            = 0      # needs full body to trace data flows
}

# ---------------------------------------------------------------------------
# Pre-built artifact static table (only paths that exist on disk are included)
# ---------------------------------------------------------------------------
$staticArtifacts = @{
    'unit-test-coverage'  = @('code-review/test-diffs.md')
    'testability'         = @()
    'ripple-effect'       = @('code-review/symbol-index.md', 'code-review/dead-code-candidates.md')
    'performance'         = @('code-review/symbol-index.md')
    'extensibility'       = @('code-review/symbol-index.md')
    'maintainability'     = @('code-review/dead-code-candidates.md')
    'structural-patterns' = @()
    'security'            = @()
}

# ---------------------------------------------------------------------------
# Assemble slices and build index rows
# ---------------------------------------------------------------------------
$indexRows = [System.Collections.Generic.List[hashtable]]::new()

foreach ($auditorName in $manifest.auditors.PSObject.Properties.Name) {
    $entry = $manifest.auditors.$auditorName

    $sb = [System.Text.StringBuilder]::new()
    [void]$sb.AppendLine("# Changeset Slice — $auditorName")
    [void]$sb.AppendLine("<!-- Assembled by build-slices.ps1 from dispatch-manifest.json -->")
    [void]$sb.AppendLine()

    # Section A always included
    [void]$sb.AppendLine('## Section A - Commit Messages')
    [void]$sb.AppendLine()
    [void]$sb.AppendLine($sectionA)
    [void]$sb.AppendLine()

    # Section B chunks
    if ($entry.files_B -and $entry.files_B.Count -gt 0) {
        [void]$sb.AppendLine('## Section B - Diff Hunks')
        [void]$sb.AppendLine()
        foreach ($f in $entry.files_B) {
            $key = "$f|B"
            if ($chunks.ContainsKey($key)) {
                [void]$sb.AppendLine("<!-- CHUNK file=`"$f`" section=`"B`" -->")
                [void]$sb.AppendLine($chunks[$key])
                [void]$sb.AppendLine('<!-- /CHUNK -->')
                [void]$sb.AppendLine()
            }
        }
    }

    # Section C chunks
    if ($entry.files_C -and $entry.files_C.Count -gt 0) {
        [void]$sb.AppendLine('## Section C - Full Source Content')
        [void]$sb.AppendLine()
        $capLines = if ($sectionCCaps.ContainsKey($auditorName)) { $sectionCCaps[$auditorName] } else { 300 }
        foreach ($f in $entry.files_C) {
            $key = "$f|C"
            if ($chunks.ContainsKey($key)) {
                $chunkContent = $chunks[$key]
                if ($capLines -gt 0) {
                    $chunkLineArr = $chunkContent -split '\r?\n'
                    if ($chunkLineArr.Count -gt $capLines) {
                        $chunkContent = ($chunkLineArr[0..($capLines - 1)] -join "`n") +
                            "`n<!-- SECTION-C-TRUNCATED: $($chunkLineArr.Count) total lines, showing first $capLines -->"
                    }
                }
                [void]$sb.AppendLine("<!-- CHUNK file=`"$f`" section=`"C`" -->")
                [void]$sb.AppendLine($chunkContent)
                [void]$sb.AppendLine('<!-- /CHUNK -->')
                [void]$sb.AppendLine()
            }
        }
    }

    # Section D
    if ($entry.include_section_D -and $sectionD) {
        [void]$sb.AppendLine('<!-- SECTION:D -->')
        [void]$sb.AppendLine($sectionD)
        [void]$sb.AppendLine('<!-- /SECTION:D -->')
        [void]$sb.AppendLine()
    }

    # Section E
    if ($entry.include_section_E -and $sectionE) {
        [void]$sb.AppendLine('<!-- SECTION:E -->')
        [void]$sb.AppendLine($sectionE)
        [void]$sb.AppendLine('<!-- /SECTION:E -->')
        [void]$sb.AppendLine()
    }

    $sliceContent = $sb.ToString()
    $slicePath    = "code-review/slices/changeset-$auditorName.md"
    $slicePath_tmp = "code-review/slices/changeset-$auditorName.tmp.md"

    $sliceContent | Set-Content $slicePath_tmp

    # Measure ratio using the existing script
    $ratioOutput = & powershell -File "$scriptDir\measure-slice-ratio.ps1" `
        -SlicePath $slicePath_tmp `
        -FullPath  $ChangesetPath

    $ratio = if ($ratioOutput -match '([\d.]+)') { [decimal]$matches[1] } else { 1.0 }
    $ratioPercent = [math]::Round($ratio * 100, 1)

    if ($ratio -lt $Threshold) {
        Move-Item $slicePath_tmp $slicePath -Force
        $changesetInput = $slicePath
        $coverageEst    = "$ratioPercent%"
        Write-Host "  ${auditorName}: slice kept (${ratioPercent}% of full changeset)"
    } else {
        Remove-Item $slicePath_tmp -ErrorAction SilentlyContinue
        $changesetInput = $ChangesetPath
        $coverageEst    = "100% (threshold)"
        Write-Host "  ${auditorName}: threshold exceeded (${ratioPercent}%) — pointing to full changeset"
    }

    # Resolve pre-built artifacts (only include paths that exist on disk)
    $artifacts = @()
    if ($staticArtifacts.ContainsKey($auditorName)) {
        foreach ($a in $staticArtifacts[$auditorName]) {
            if (Test-Path $a) { $artifacts += $a }
        }
    }
    $artifactCell = if ($artifacts.Count -gt 0) { $artifacts -join '; ' } else { '—' }

    $indexRows.Add(@{
        Auditor        = $auditorName
        ChangesetInput = $changesetInput
        Artifacts      = $artifactCell
        CoverageEst    = $coverageEst
    })
}

# ---------------------------------------------------------------------------
# Write auditor-input-index.md
# The ## Shared Context placeholder is filled by REVIEW-CodeCorrectnessAuditor in Stage 3.
# ---------------------------------------------------------------------------
$idx = [System.Text.StringBuilder]::new()
[void]$idx.AppendLine('# Auditor Input Index')
[void]$idx.AppendLine()
[void]$idx.AppendLine('## Shared Context')
[void]$idx.AppendLine('<!-- BRIEF: pending — filled by Correctness Auditor in Stage 3 -->')
[void]$idx.AppendLine()
[void]$idx.AppendLine('---')
[void]$idx.AppendLine('_Generated by REVIEW-ChangesetDispatcher via build-slices.ps1. Each auditor reads only the files listed in its row._')
[void]$idx.AppendLine()
[void]$idx.AppendLine('| Auditor | Changeset Input | Pre-built Artifacts | Coverage Est. | Notes |')
[void]$idx.AppendLine('|---------|----------------|---------------------|---------------|-------|')

foreach ($row in $indexRows) {
    [void]$idx.AppendLine("| $($row.Auditor) | $($row.ChangesetInput) | $($row.Artifacts) | $($row.CoverageEst) | |")
}

$idx.ToString() | Set-Content 'code-review/auditor-input-index.md'
Write-Host "Auditor input index written to code-review/auditor-input-index.md"
Write-Host "Slices: $($indexRows.Count) auditors processed"
