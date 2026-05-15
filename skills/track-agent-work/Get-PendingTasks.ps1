# Get-PendingTasks.ps1
#
# Lists all non-completed, non-deleted tasks from the prod TaskTracker database.
# Outputs a JSON array to stdout. Returns exit code 0 on success, 1 on failure.
#
# Usage: .\Get-PendingTasks.ps1

$tt = "D:\Repos_D\TaskTracker\src\TaskTracker.Cli\bin\Debug\net10.0\TaskTracker.Cli.exe"

if (-not (Test-Path $tt)) {
    Write-Error "tt CLI not found at: $tt"
    exit 1
}

$env:ASPNETCORE_ENVIRONMENT = "Production"
try {
    $raw = & $tt list --status all 2>&1
    $tasks = ($raw | ConvertFrom-Json) | Where-Object { $_.status -lt 3 -and -not $_.isDeleted }
    $tasks | ConvertTo-Json -Depth 5
}
catch {
    Write-Error "Failed to list tasks: $_"
    exit 1
}
finally {
    $env:ASPNETCORE_ENVIRONMENT = ""
}
