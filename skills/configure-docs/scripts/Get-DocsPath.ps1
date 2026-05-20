# Get-DocsPath.ps1
# Resolves the configured documentation directory for the given (or current) workspace.
#
# Usage:
#   .\Get-DocsPath.ps1                        # uses current directory
#   .\Get-DocsPath.ps1 -WorkspacePath <path>  # explicit path
#
# Output (stdout, one line):
#   <docs-path>      — configured and active
#   DOCS_DISABLED    — workspace has opted out
#   NOT_CONFIGURED   — no entry exists for this workspace
#
# Exit code: 0 always (consumers branch on the output string).

param(
    [string]$WorkspacePath = (Get-Location).Path
)

$configPath = Join-Path $HOME "Repos/vs-code-copilot-tools/workspace-docs.json"

# Normalize: lowercase, backslashes → forward slashes, no trailing slash
$normalized = $WorkspacePath.ToLower().Replace('\', '/').TrimEnd('/')

if (-not (Test-Path $configPath)) {
    Write-Output "NOT_CONFIGURED"
    exit 0
}

$config = Get-Content $configPath -Raw | ConvertFrom-Json

$value = $config.workspaces.$normalized

if ($null -eq $value) {
    Write-Output "NOT_CONFIGURED"
} else {
    Write-Output $value
}
