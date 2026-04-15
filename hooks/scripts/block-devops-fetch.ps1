# PreToolUse hook: block external API/DevOps fetch attempts in RequirementsAuditor
# Reads tool input from stdin, exits 2 (blocking) if forbidden patterns are detected.

$input_json = $Input | Out-String | ConvertFrom-Json

$toolName = $input_json.tool_name

# Only check terminal commands
if ($toolName -notmatch 'runInTerminal|execute|terminal') { exit 0 }

$command = if ($null -ne $input_json.tool_input.command) { $input_json.tool_input.command } elseif ($null -ne $input_json.tool_input.input) { $input_json.tool_input.input } else { "" }
if (-not $command) { exit 0 }

$forbidden = @(
    'az\s+boards',
    'az\s+devops',
    'gh\s+api',
    'gh\s+issue',
    'gh\s+pr',
    'Invoke-RestMethod.*devops\.microsoft\.com',
    'Invoke-WebRequest.*devops\.microsoft\.com',
    'curl.*api\.github\.com',
    'curl.*devops\.microsoft\.com',
    'Invoke-RestMethod.*visualstudio\.com',
    'Invoke-WebRequest.*visualstudio\.com'
)

foreach ($pattern in $forbidden) {
    if ($command -match $pattern) {
        Write-Error "BLOCKED: Fetching work item details from external systems is forbidden. Per REVIEW-CONVENTIONS: ask the user to paste the work item content directly into the chat. Matched pattern: $pattern"
        exit 2
    }
}

exit 0
