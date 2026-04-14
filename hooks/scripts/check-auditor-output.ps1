# SubagentStop hook: verify each parallel auditor wrote its expected output file
# Reads subagent info from stdin, injects a warning if the output file is missing.

$input_json = $Input | Out-String | ConvertFrom-Json

$agentType = $input_json.agent_type ?? ""

# Map auditor agent names to their expected output files
$outputMap = @{
    'REVIEW-MaintainabilityAuditor'   = 'code-review/maintainability-audit.md'
    'REVIEW-TestabilityAuditor'       = 'code-review/testability-audit.md'
    'REVIEW-PerformanceAuditor'       = 'code-review/performance-audit.md'
    'REVIEW-ExtensibilityAuditor'     = 'code-review/extensibility-audit.md'
    'REVIEW-UnitTestCoverageAuditor'  = 'code-review/unit-test-coverage-audit.md'
}

if (-not $outputMap.ContainsKey($agentType)) { exit 0 }

$expectedFile = $outputMap[$agentType]
$cwd = $input_json.cwd ?? (Get-Location).Path
$fullPath = Join-Path $cwd $expectedFile

if (-not (Test-Path $fullPath)) {
    $output = @{
        hookSpecificOutput = @{
            hookEventName   = 'SubagentStop'
            additionalContext = "WARNING: $agentType completed but its expected output file '$expectedFile' was not found. The auditor may have failed silently. Review the subagent output before proceeding to final synthesis."
        }
    } | ConvertTo-Json -Compress
    Write-Output $output
}

exit 0
