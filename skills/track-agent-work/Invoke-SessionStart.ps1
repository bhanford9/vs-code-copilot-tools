# Invoke-SessionStart.ps1
#
# Claims an existing prod TaskTracker task and marks it In Progress.
# Outputs the updated task as JSON to stdout.
# Returns exit code 0 on success, 1 on failure.
#
# Usage: .\Invoke-SessionStart.ps1 -TaskId <guid>

param(
    [Parameter(Mandatory)]
    [string]$TaskId
)

$tt = "D:\Repos_D\TaskTracker\src\TaskTracker.Cli\bin\Debug\net10.0\TaskTracker.Cli.exe"

if (-not (Test-Path $tt)) {
    Write-Error "tt CLI not found at: $tt"
    exit 1
}

$env:ASPNETCORE_ENVIRONMENT = "Production"
try {
    $raw = & $tt start --id $TaskId 2>&1
    $raw  # pass through to caller
}
catch {
    Write-Error "session-start failed: $_"
    exit 1
}
finally {
    $env:ASPNETCORE_ENVIRONMENT = ""
}
