# PostToolUse hook: detect inline comments in *Tests.cs files
# Reads tool input from stdin, exits 2 (blocking) if comments are found.

$input_json = $Input | Out-String | ConvertFrom-Json

$toolName = $input_json.tool_name
$toolInput = $input_json.tool_input

# Only care about file edits
$filePath = if ($toolInput.filePath) { $toolInput.filePath } elseif ($toolInput.file_path) { $toolInput.file_path } else { "" }
if (-not $filePath) { exit 0 }

# Only care about *Tests.cs files
if ($filePath -notmatch 'Tests\.cs$') { exit 0 }

# Read the file content
if (-not (Test-Path $filePath)) { exit 0 }

$lines = Get-Content $filePath
$violations = @()

for ($i = 0; $i -lt $lines.Count; $i++) {
    $line = $lines[$i]
    $trimmed = $line.TrimStart()

    # Skip XML doc comments (///) and blank lines
    if ($trimmed -match '^///' -or $trimmed -eq '') { continue }

    # Detect inline // comments (not inside strings — best-effort)
    if ($trimmed -match '^//') {
        $violations += "  L$($i + 1): $($trimmed.Substring(0, [Math]::Min(80, $trimmed.Length)))"
    }

    # Detect /* block comments
    if ($trimmed -match '/\*') {
        $violations += "  L$($i + 1): $($trimmed.Substring(0, [Math]::Min(80, $trimmed.Length)))"
    }
}

if ($violations.Count -gt 0) {
    $msg = "ADVISORY: Comments detected in test file '$([System.IO.Path]::GetFileName($filePath))'. Test code should be self-documenting through naming. If you wrote these comments, remove them and express intent through better naming instead. If these comments were pre-existing (not written by you in this edit), leave them unchanged. Violations:`n" + ($violations -join "`n")
    Write-Host $msg
    exit 0
}

exit 0
