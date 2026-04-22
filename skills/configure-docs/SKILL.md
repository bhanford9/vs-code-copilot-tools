---
name: configure-docs
description: Resolve the documentation directory for the current workspace from machine-local config. Handles first-time setup, path management, and opt-out toggling. Use when any skill or agent needs to locate or configure the knowledge base directory for the active workspace, or when documentation configuration needs to be checked, changed, or established for the first time.
---

# Configure Docs

> This skill is the single source of truth for resolving where documentation lives for any workspace on this machine. All documentation-aware skills delegate to this skill rather than asking the user for a path. It also serves as the entry point for a user who wants to set up, change, or opt out of automated documentation.

## Quick Checklist

```
Configure Docs Session:
- [ ] Read LessonsLearned.GLOBAL.md and LessonsLearned.md (if present)
- [ ] Step 1: Perform Workspace Docs Lookup — read config, determine branch
- [ ] Step 2: Execute branch action (use path / opt-out / prompt user)
- [ ] Step 3: If managing config — show state, apply requested change
- [ ] Step 4: Lessons Learned (if something was hard or went wrong)
```

---

## Config File

The configuration lives at a fixed, machine-local path:

```
~/Repos/vs-code-copilot-tools/workspace-docs.json
```

This file is **gitignored** — it is unique to each machine and must never be committed. Create it (using the schema below) if it does not exist.

**Schema:**
```json
{
  "_comment": "Machine-local config — do not commit. Managed by the configure-docs skill.",
  "_instructions": "Map each workspace root path (normalized: lowercase, forward slashes, no trailing slash) to its documentation directory path, or to DOCS_DISABLED to opt out of automated documentation.",
  "workspaces": {
    "<normalized-workspace-path>": "<docs-directory-path> | DOCS_DISABLED"
  }
}
```

**Path normalization rules** — apply to all workspace keys:
- Lowercase all characters
- Replace all backslashes (`\`) with forward slashes (`/`)
- Remove any trailing slash

**Example:**
```json
{
  "_comment": "Machine-local config — do not commit. Managed by the configure-docs skill.",
  "_instructions": "...",
  "workspaces": {
    "c:/users/bmhanford/repos/myapp": "c:/users/bmhanford/docs/myapp/architecture",
    "c:/users/bmhanford/repos/legacyapp": "DOCS_DISABLED"
  }
}
```

---

## Step 1: Workspace Docs Lookup Procedure

> **This is the canonical lookup.** Any skill or agent that needs a documentation directory must invoke this skill rather than duplicating this logic.

1. **Determine the workspace key.** Normalize `cwd` to lowercase, backslashes → forward slashes, no trailing slash.
2. **Read** `~/Repos/vs-code-copilot-tools/workspace-docs.json`.
   - If the file does not exist: create it using the schema above with an empty `workspaces` object, then go to step 4.
3. **Look up the normalized workspace path** as a key in `workspaces`:
   - Value is a path → **configured** — return the path to the caller. Done.
   - Value is `"DOCS_DISABLED"` → **opted out** — go to Step 2 (Opt-Out Branch).
   - Key is missing → **unconfigured** — go to step 4.
4. **Unconfigured.** Go to Step 2 (Unconfigured Branch).

---

## Step 2: Branch Actions

### Configured — Path Found

Return the resolved path to the calling skill or agent. No user interaction needed.

### Opt-Out Branch

| Invocation type | Behavior |
|---|---|
| Automated (e.g., harvest running at session end) | Return `DOCS_DISABLED` to the caller. Caller skips silently — no user prompt, no mention of docs. |
| Manual (user explicitly invoked a doc-writing or doc-reading skill) | Inform the user: "Automated documentation is disabled for this workspace. Run `configure-docs` to set a path or re-enable it." Stop. |

### Unconfigured Branch

Ask the user:

> "No documentation directory is configured for `{workspace}`. Would you like to:
> 1. Provide a path to an existing documentation directory
> 2. Disable automated documentation for this workspace (`DOCS_DISABLED`)
> 3. Skip for now (no change saved)"

- **Choice 1**: prompt for the path, normalize it, write it to `workspaces` under the normalized workspace key. Return the path to the caller.
- **Choice 2**: write `"DOCS_DISABLED"` under the normalized workspace key. Follow Opt-Out Branch above.
- **Choice 3**: do not write anything. Return `SKIPPED` to the caller. Caller stops without error.

---

## Step 3: Managing Configuration (User-Initiated)

When a user runs this skill directly (e.g., via the `configure-docs` prompt), show the current configuration state first:

```
Workspace: {normalized-cwd}
Current config: {path | DOCS_DISABLED | not configured}
```

Then offer:
1. Set or change the documentation directory path
2. Toggle opt-out (`DOCS_DISABLED` ↔ active path)
3. Remove this workspace's entry entirely
4. View all configured workspaces

Apply the requested change and confirm.

---

## Step 4: Lessons Learned

Update LessonsLearned files at the end of any session where something was hard, surprising, or went wrong:

- **`LessonsLearned.md`** (local, gitignored) — machine-specific observations: paths that were tricky to normalize, workspaces that needed special handling.
- **`LessonsLearned.GLOBAL.md`** (tracked in git) — process improvements: lookup failures, config schema issues, branch logic gaps.

Only write an entry if something was hard or went wrong. Do not document smooth sessions.
