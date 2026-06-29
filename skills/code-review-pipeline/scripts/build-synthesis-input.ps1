# build-synthesis-input.ps1
#
# Reads the first 3 lines of each *-audit.md in code-review/ and applies three read-trigger rules.
# Outputs one file path per line to stdout for each report that should be read in full.
# Outputs nothing for clean reports.
#
# Read triggers:
#   1. Verdict = BLOCKED
#   2. Any 🔴 present
#   3. Any 🟠 present
#   4. Total finding count (🔴 + 🟠 + 🟡 + 🟢) > TotalFindingsThreshold
#
# Usage:
#   powershell -File build-synthesis-input.ps1
#   powershell -File build-synthesis-input.ps1 -TotalFindingsThreshold 8

param(
    [string]$ReviewDir              = 'code-review',
    [int]   $TotalFindingsThreshold = 10
)

$auditFiles = Get-ChildItem $ReviewDir -Filter '*-audit.md' | Sort-Object Name

if ($auditFiles.Count -eq 0) {
    Write-Warning "No *-audit.md files found in $ReviewDir"
    exit 0
}

foreach ($f in $auditFiles) {
    $lines     = Get-Content $f.FullName -TotalCount 3
    $titleLine = if ($lines.Count -ge 1) { $lines[0] } else { '' }
    $statsLine = if ($lines.Count -ge 2) { $lines[1] } else { '' }

    $counts = @{ red = 0; orange = 0; yellow = 0; green = 0 }
    foreach ($seg in ($statsLine -split '\|')) {
        if ($seg -match '🔴[^0-9]*(\d+)') { $counts.red    = [int]$Matches[1] }
        if ($seg -match '🟠[^0-9]*(\d+)') { $counts.orange = [int]$Matches[1] }
        if ($seg -match '🟡[^0-9]*(\d+)') { $counts.yellow = [int]$Matches[1] }
        if ($seg -match '🟢[^0-9]*(\d+)') { $counts.green  = [int]$Matches[1] }
    }
    $total = $counts.red + $counts.orange + $counts.yellow + $counts.green

    $shouldRead = ($titleLine -match 'BLOCKED') -or
                  ($counts.red    -gt 0) -or
                  ($counts.orange -gt 0) -or
                  ($total -gt $TotalFindingsThreshold)

    if ($shouldRead) {
        Write-Output "$ReviewDir/$($f.Name)"
    }
}
