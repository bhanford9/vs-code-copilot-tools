# For each changed non-test .cs source file, resolves the expected test file path
# using naming convention and checks whether it exists at that exact location.
#
# Called by build-changeset.ps1. Returns the index as a string (Section E content).
#
# Convention:
#   Source:  Some/Path/MyProject/Sub/Folder/MyClass.cs
#   Tests:   Some/Path/MyProjectTests/Sub/Folder/MyClassTests.cs
#
# The project root is located by walking up from the source file until a directory
# containing a .csproj file is found. The test project is the sibling folder named
# "{ProjectFolder}Tests". Subdirectory structure within the project is preserved.
# If not found at that exact path, it is reported as missing from expected location.
#
# Usage: & build-test-index.ps1 -ChangedFiles $changedFiles

param(
    [string[]]$ChangedFiles = @()
)

if (-not $ChangedFiles -or $ChangedFiles.Count -eq 0) {
    return '> No changed source files detected. Test file index skipped.'
}

$repoRoot = (Get-Location).Path

# Walk up from $startDir until a directory containing a .csproj is found.
# Returns $null if none found before reaching the repo root.
function Find-ProjectRoot([string]$startDir) {
    $dir = $startDir
    while ($dir -and $dir.Length -ge $repoRoot.Length) {
        if (Get-ChildItem -Path $dir -Filter '*.csproj' -ErrorAction SilentlyContinue) {
            return $dir
        }
        $parent = [System.IO.Path]::GetDirectoryName($dir)
        if ($parent -eq $dir) { break }
        $dir = $parent
    }
    return $null
}

$sb = [System.Text.StringBuilder]::new()
[void]$sb.AppendLine('| Source File | Expected Test File | Exists? |')
[void]$sb.AppendLine('|---|---|---|')

foreach ($file in $ChangedFiles) {
    if (-not (Test-Path $file)) { continue }

    $relSource  = $file -replace [regex]::Escape($repoRoot + '\'), '' -replace '\\', '/'
    $sourceDir  = [System.IO.Path]::GetDirectoryName($file)
    $sourceName = [System.IO.Path]::GetFileNameWithoutExtension($file)

    $projectRoot = Find-ProjectRoot $sourceDir

    if (-not $projectRoot) {
        [void]$sb.AppendLine("| $relSource | (no .csproj found in path) | ? Unknown |")
        continue
    }

    $projectName  = [System.IO.Path]::GetFileName($projectRoot)
    $projectParent = [System.IO.Path]::GetDirectoryName($projectRoot)

    # Relative path from project root to the source file's directory (may be empty)
    $subPath = $sourceDir.Substring($projectRoot.Length).TrimStart('\', '/')

    $testProjectDir = Join-Path $projectParent "${projectName}Tests"
    $testFileDir    = if ($subPath) { Join-Path $testProjectDir $subPath } else { $testProjectDir }
    $expectedTestFile = Join-Path $testFileDir "${sourceName}Tests.cs"
    $relTest = $expectedTestFile -replace [regex]::Escape($repoRoot + '\'), '' -replace '\\', '/'

    if (Test-Path $expectedTestFile) {
        [void]$sb.AppendLine("| $relSource | [$relTest]($relTest) | Yes |")
    } else {
        [void]$sb.AppendLine("| $relSource | $relTest | MISSING - expected location not found |")
    }
}

return $sb.ToString()
