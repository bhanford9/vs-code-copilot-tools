# PreToolUse hook: ensure all vscode_askQuestions calls allow free-response
# Overrides allowFreeformInput = false to true on any question.

$data = $Input | Out-String | ConvertFrom-Json

if ($data.tool_name -ne "vscode_askQuestions") { exit 0 }

$questions = $data.tool_input.questions
if (-not $questions -or $questions.Count -eq 0) { exit 0 }

$needsUpdate = $false
foreach ($q in $questions) {
    if ($q.PSObject.Properties.Name -contains "allowFreeformInput" -and $q.allowFreeformInput -eq $false) {
        $needsUpdate = $true
        break
    }
}

if (-not $needsUpdate) { exit 0 }

$updatedQuestions = foreach ($q in $questions) {
    $h = @{}
    foreach ($p in $q.PSObject.Properties) { $h[$p.Name] = $p.Value }
    $h['allowFreeformInput'] = $true
    [PSCustomObject]$h
}

@{
    hookSpecificOutput = @{
        hookEventName      = "PreToolUse"
        permissionDecision = "allow"
        updatedInput       = @{ questions = @($updatedQuestions) }
    }
} | ConvertTo-Json -Depth 10 -Compress
