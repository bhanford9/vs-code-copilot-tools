# Code Review Pipeline — New Repo Setup

Follow these steps the first time you use this pipeline against a repository.

---

## Step 1 — Optional: place config files in the git common dir

The pipeline reads two optional config files from the repository's **git common directory** —
shared across all worktrees, never committed to the repo, never tracked by git.

Find the common dir:
```powershell
git rev-parse --git-common-dir
# e.g. C:/Users/you/source/repos/myrepo/.git
```

### `review-exclusions.json` — artifact exclusions for diff + security classifier

Copy the bundled template and edit it for your repo:

```powershell
$dst = "$(git rev-parse --git-common-dir)/review-exclusions.json"
Copy-Item "$env:USERPROFILE/Repos/vs-code-copilot-tools/skills/code-review-pipeline/review-exclusions.example.json" $dst
# Then open $dst and replace the example values with your repo's artifact extensions and paths
```

**`extensionExcludes`** — file extensions that are always generated/binary and never reviewable
(e.g. `*.fja`, `*.std`, `*.snap`). The diff for these files is silently omitted.

**`pathExcludes`** — directory trees containing only fixture or artifact storage, not source code
(e.g. `**/IntegrationTests/**`, `**/fixtures/**`). All files under these paths are excluded.

If omitted: only the built-in `TestResources/**` exclusion applies.

---

### `check-captive-dependencies.ps1` — stack-specific DI validation (optional)

Provide this script only if your codebase has a known **captive dependency** risk pattern
(e.g. Singleton services capturing Scoped dependencies in a DI container).

**Contract:** the script must write its findings to `code-review/captive-deps.md`.
The Ripple Effect auditor reads this file if it exists.

```powershell
# Minimal stub — replace with your actual validation logic
# Output: code-review/captive-deps.md

$findings = @()
# ... your stack-specific checks here ...

if ($findings.Count -eq 0) {
    "## Captive Dependency Check`n`nNo captive dependencies detected." |
        Set-Content 'code-review/captive-deps.md'
} else {
    $findings | Set-Content 'code-review/captive-deps.md'
}
```

Place at: `$(git rev-parse --git-common-dir)/check-captive-dependencies.ps1`

If omitted: the pipeline skips captive dependency checking silently.

---

## Step 2 — Optional: configure the ADO work item fetcher

The Requirements Auditor auto-fetches Azure DevOps work items if the
`fetch-azure-devops-work-item` skill is configured in the repo's `.claude/skills/` directory.

If not configured, the auditor will ask you to provide work item details manually and continue.
No pipeline failure occurs.

---

## Step 3 — Verify setup

Run these two scripts from the repo root and check the output:

```powershell
# Should print "Loaded workspace exclusions from git common dir" if exclusions file exists
powershell -File ~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/scripts/detect-base-branch.ps1

# Should print "Loaded workspace exclusions from git common dir (N ext, N path)" if file exists
# Should print "Running workspace-local captive dependency check..." if script exists
powershell -File ~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/scripts/build-changeset.ps1
```

---

## What happens without any setup

The pipeline works with no configuration at all — all optional files are gracefully skipped.
The trade-off is:

- Fixture/artifact files **will appear in diffs** and inflate `changeset-full.md`
- Any file named with a security-pattern keyword (`Repository`, `Validate`, etc.) anywhere in its
  path will trigger `securitySurface = true` and launch the full security audit
- Captive dependency checking is skipped

For small repos or repos without large fixture files, no setup is needed.
