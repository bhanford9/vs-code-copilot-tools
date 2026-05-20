# Set-DocsPath.ps1
# Writes or updates the documentation directory entry for the given workspace.
#
# Usage:
#   .\Set-DocsPath.ps1 -DocsPath <path>                        # uses current directory as workspace
#   .\Set-DocsPath.ps1 -WorkspacePath <ws> -DocsPath <path>    # explicit workspace
#   .\Set-DocsPath.ps1 -WorkspacePath <ws> -DocsPath DOCS_DISABLED  # opt out
#   .\Set-DocsPath.ps1 -WorkspacePath <ws> -Remove             # remove entry entirely
#
# Exit code: 0 on success, 1 on error.

param(
    [string]$WorkspacePath = (Get-Location).Path,
    [string]$DocsPath = "",
    [switch]$Remove
)

if (-not $Remove -and [string]::IsNullOrWhiteSpace($DocsPath)) {
    Write-Error "Provide -DocsPath <path> or -DocsPath DOCS_DISABLED, or use -Remove."
    exit 1
}

$configPath = Join-Path $HOME "Repos/vs-code-copilot-tools/workspace-docs.json"

# Normalize workspace key: lowercase, backslashes → forward slashes, no trailing slash
$normalized = $WorkspacePath.ToLower().Replace('\', '/').TrimEnd('/')

# Load or initialize config
if (Test-Path $configPath) {
    $config = Get-Content $configPath -Raw | ConvertFrom-Json
} else {
    $config = [PSCustomObject]@{
        _comment      = "Machine-local config — do not commit. Managed by the configure-docs skill."
        _instructions = "Map each workspace root path (normalized: lowercase, forward slashes, no trailing slash) to its documentation directory path, or to DOCS_DISABLED to opt out of automated documentation."
        workspaces    = [PSCustomObject]@{}
    }
}

# Ensure workspaces property exists
if ($null -eq $config.workspaces) {
    $config | Add-Member -NotePropertyName workspaces -NotePropertyValue ([PSCustomObject]@{})
}

if ($Remove) {
    $config.workspaces.PSObject.Properties.Remove($normalized)
    Write-Host "Removed entry for: $normalized"
} else {
    # Normalize docs path (unless it's the sentinel value)
    $normalizedDocs = if ($DocsPath -eq "DOCS_DISABLED") {
        "DOCS_DISABLED"
    } else {
        $DocsPath.ToLower().Replace('\', '/').TrimEnd('/')
    }

    if ($config.workspaces.PSObject.Properties[$normalized]) {
        $config.workspaces.$normalized = $normalizedDocs
    } else {
        $config.workspaces | Add-Member -NotePropertyName $normalized -NotePropertyValue $normalizedDocs
    }
    Write-Host "Set [$normalized] = $normalizedDocs"
}

$config | ConvertTo-Json -Depth 5 | Set-Content $configPath -Encoding UTF8
Write-Host "Saved: $configPath"
exit 0
