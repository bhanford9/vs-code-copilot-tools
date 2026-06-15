# Measures the line-count ratio of a candidate slice file relative to the full changeset.
# Used by REVIEW-ChangesetDispatcher to decide whether to keep a slice or point directly
# to changeset-full.md (75% threshold).
#
# Output: a single decimal value (e.g. 0.82) written to stdout.
# Exit code 0 always — the caller checks the ratio value.
#
# Usage (from repo root):
#   powershell -File scripts/measure-slice-ratio.ps1 -SlicePath "code-review/slices/changeset-performance.md" -FullPath "code-review/changeset-full.md"
#
# Dispatcher decision rule:
#   ratio < 0.75  → keep the slice; write SlicePath to auditor-input-index.md
#   ratio >= 0.75 → discard the slice; write FullPath to auditor-input-index.md

param(
    [Parameter(Mandatory)][string]$SlicePath,
    [Parameter(Mandatory)][string]$FullPath
)

if (-not (Test-Path $SlicePath)) {
    Write-Error "SlicePath not found: $SlicePath"
    exit 1
}
if (-not (Test-Path $FullPath)) {
    Write-Error "FullPath not found: $FullPath"
    exit 1
}

$sliceLines = (Get-Content $SlicePath | Measure-Object -Line).Lines
$fullLines  = (Get-Content $FullPath  | Measure-Object -Line).Lines

if ($fullLines -eq 0) {
    Write-Host "0.00"
    exit 0
}

$ratio = [math]::Round($sliceLines / $fullLines, 2)
Write-Host $ratio
