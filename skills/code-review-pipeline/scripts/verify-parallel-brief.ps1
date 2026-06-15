# Verifies that code-review/parallel-brief.md was written by the
# CorrectnessAuditor and that code-review/auditor-input-index.md was written
# by the ChangesetDispatcher. Both must exist before Stage 5 (parallel auditors) runs.
#
# Exit code 0  — both files are valid; pipeline may proceed to Stage 5.
# Exit code 1  — one or both files are missing or incomplete; Orchestrator must stop.
#
# Usage: Run from the root of the repository being reviewed.

$briefPath  = 'code-review/parallel-brief.md'
$indexPath  = 'code-review/auditor-input-index.md'

$briefExists = Test-Path $briefPath
$indexExists = Test-Path $indexPath

$briefSize   = if ($briefExists) { (Get-Item $briefPath).Length } else { 0 }
$indexSize   = if ($indexExists) { (Get-Item $indexPath).Length } else { 0 }

$briefContent = if ($briefExists) { Get-Content $briefPath -Raw } else { '' }

$hasIntent       = $briefContent -match '##\s+Intent'
$hasRequirements = $briefContent -match '##\s+Key Requirements'

Write-Host "parallel-brief.md exists: $briefExists  size: $briefSize bytes"
Write-Host "Has Intent section:        $hasIntent"
Write-Host "Has Key Requirements:      $hasRequirements"
Write-Host "auditor-input-index.md exists: $indexExists  size: $indexSize bytes"

$briefValid = $briefExists -and $briefSize -gt 100 -and $hasIntent -and $hasRequirements
$indexValid = $indexExists -and $indexSize -gt 50

if ($briefValid -and $indexValid) {
    Write-Host "RESULT: Both files valid - proceed to Stage 5."
    exit 0
} elseif (-not $briefValid) {
    Write-Host "RESULT: parallel-brief.md is missing or incomplete - Correctness Auditor may have failed."
    exit 1
} else {
    Write-Host "RESULT: auditor-input-index.md is missing or incomplete - Dispatcher may have failed."
    exit 1
}
