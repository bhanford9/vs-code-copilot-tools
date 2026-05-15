# New-TrackedTask.ps1
#
# Creates a new task in the prod TaskTracker database, then immediately claims
# it with session-start to mark it In Progress.
# Outputs a JSON object: { id, title, shortId } to stdout.
# Returns exit code 0 on success, 1 on failure.
#
# Usage:
#   .\New-TrackedTask.ps1 `
#       -Title "Fix dispatch toggle resetting in Categories page" `
#       -Description "The toggle resets to OFF after navigating away..." `
#       -Category coding `
#       -Horizon ThisWeek `
#       -Effort Medium

param(
    [Parameter(Mandatory)]
    [string]$Title,

    [Parameter(Mandatory)]
    [string]$Description,

    [ValidateSet("coding","devops","admin")]
    [string]$Category = "coding",

    [ValidateSet("Today","Immediate","ThisWeek","Someday")]
    [string]$Horizon = "ThisWeek",

    [ValidateSet("Small","Medium","Large")]
    [string]$Effort = "Medium"
)

$tt = "D:\Repos_D\TaskTracker\src\TaskTracker.Cli\bin\Debug\net10.0\TaskTracker.Cli.exe"

if (-not (Test-Path $tt)) {
    Write-Error "tt CLI not found at: $tt"
    exit 1
}

$env:ASPNETCORE_ENVIRONMENT = "Production"
try {
    # Create the task
    $addRaw = & $tt add `
        --title $Title `
        --description $Description `
        --horizon $Horizon `
        --effort $Effort `
        --category $Category 2>&1

    $addResult = ($addRaw | ConvertFrom-Json)
    $taskId = $addResult.Id

    if (-not $taskId) {
        Write-Error "Task creation did not return an id. Raw output: $addRaw"
        exit 1
    }

    # Claim it immediately (simple status set — no dispatch eligibility checks)
    & $tt start --id $taskId | Out-Null

    # Return key fields to the caller
    @{
        id      = $taskId
        title   = $addResult.Title
        shortId = $addResult.ShortId
    } | ConvertTo-Json -Compress
}
catch {
    Write-Error "New-TrackedTask failed: $_"
    exit 1
}
finally {
    $env:ASPNETCORE_ENVIRONMENT = ""
}
