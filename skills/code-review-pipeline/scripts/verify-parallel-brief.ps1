# Verifies that code-review/parallel-brief.md was written by the
# CorrectnessAuditor and meets the Definition of Done.
#
# Exit code 0  — brief is valid; pipeline may proceed to Stage 3.
# Exit code 1  — brief is missing or incomplete; Orchestrator must write it.
#
# Usage: Run from the root of the repository being reviewed.

$briefPath  = 'code-review/parallel-brief.md'
$briefExists = Test-Path $briefPath
$briefSize   = if ($briefExists) { (Get-Item $briefPath).Length } else { 0 }
$briefContent = if ($briefExists) { Get-Content $briefPath -Raw } else { '' }

$hasIntent       = $briefContent -match '##\s+Intent'
$hasRequirements = $briefContent -match '##\s+Key Requirements'

Write-Host "parallel-brief.md exists: $briefExists  size: $briefSize bytes"
Write-Host "Has Intent section:        $hasIntent"
Write-Host "Has Key Requirements:      $hasRequirements"

if ($briefExists -and $briefSize -gt 100 -and $hasIntent -and $hasRequirements) {
    Write-Host "RESULT: Brief is valid — proceed to Stage 3."
    exit 0
} else {
    Write-Host "RESULT: Brief is missing or incomplete — Orchestrator must write it."
    exit 1
}
