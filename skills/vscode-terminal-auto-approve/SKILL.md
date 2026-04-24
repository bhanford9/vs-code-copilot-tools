---
name: vscode-terminal-auto-approve
description: Add or fix VS Code auto-approval patterns for Copilot agent terminal commands. Use when: a terminal command required manual approval that should be automatic; setting up auto-approval for a new skill's scripts; debugging why a pattern is not matching; or when user says "add to auto approve", "it prompted me to approve", or "terminal kept asking for approval".
---

# VS Code Terminal Auto-Approve — SKILL.md

## Purpose

Copilot agent terminal commands require user approval unless a matching pattern exists in `chat.tools.terminal.autoApprove` in VS Code's `settings.json`. This skill documents how that setting works and how to write patterns that actually match.

---

## Step 1 — Read Lessons Learned

Read [LessonsLearned.GLOBAL.md](./LessonsLearned.GLOBAL.md) and, if it exists on disk, [LessonsLearned.md](./LessonsLearned.md) for any known pitfalls from past sessions. Apply anything relevant before proceeding.

---

## Step 2 — Read the Official Documentation

Fetch and read the official VS Code documentation before writing any patterns:

**URL:** https://code.visualstudio.com/docs/copilot/agents/agent-tools#_automatically-approve-terminal-commands

Key sections to understand:
- The difference between **subcommand matching** (default) and **full command line matching** (`matchCommandLine: true`)
- The format for regex patterns (wrapped in `/` delimiters)
- The `true` / `false` / object value formats
- Security cautions about auto-approval

This step is mandatory — the setting behavior and format have evolved across VS Code versions, and the official docs are the ground truth.

---

## Step 3 — Understand the Setting

The setting lives at:

```
%APPDATA%\Code\User\settings.json
```

Under the key `chat.tools.terminal.autoApprove`. Each entry is a key-value pair where:

- **Key** — a plain string prefix, or a `/regex/` pattern wrapped in `/` delimiters
- **Value** — `true` (approve), `false` (always deny), or `{"approve": true/false, "matchCommandLine": true}` (full command line mode)

### Two Matching Modes

**Default (subcommand matching):** VS Code parses the command and matches patterns against individual subcommands. Works well for simple commands. Use `true` as the value.

```jsonc
"mkdir": true,
"/^git (status|show\\b.*)$/": true,
"del": false,
```

**Full command line matching (`matchCommandLine: true`):** Matches the entire raw command string instead of parsed subcommands. Required when:
- The command starts with `&` (PowerShell call operator) — not recognized as a standard subcommand by VS Code's parser
- Subcommand parsing would miss the match for any other reason

```jsonc
"/^& \".*\\.github\\\\skills\\\\.*\\.ps1\"/": {
  "approve": true,
  "matchCommandLine": true
},
```

> **Why `matchCommandLine` is needed for skill scripts:** Commands like `& "d:\...\script.ps1" -Param value` use PowerShell's call operator (`&`). VS Code's subcommand parser does not recognize this form, so it never matches — even with a correct regex and a `true` value. `matchCommandLine: true` bypasses the parser and matches the raw command string directly.

### Pattern Format

Wrap regex patterns in `/` delimiters:

```
"/^<regex>/": true            (subcommand mode)
"/^<regex>/": { "approve": true, "matchCommandLine": true }   (full command line mode)
```

- `^` anchors to the start of the command string — always include it
- Escape backslashes: each literal `\` in the regex requires `\\` in the JSON key
- No trailing `.*` needed — prefix matching is sufficient once anchored

### Examples

```jsonc
"chat.tools.terminal.autoApprove": {
  // Simple subcommand match — plain true
  "dotnet build": true,
  "mkdir": true,

  // Regex with subcommand matching — plain true works
  "/^git (status|show\\b.*)$/": true,

  // Full command line match — needed for & "path\script.ps1" style
  "/^& \".*\\.github\\\\skills\\\\my-skill\\\\scripts\\\\.*\\.ps1\"/": {
    "approve": true,
    "matchCommandLine": true
  },

  // Full command line match for dotnet run with a specific project
  "/^dotnet run --project .*MyProject/": {
    "approve": true,
    "matchCommandLine": true
  }
}
```

---

## Step 4 — Write the Pattern

When adding auto-approval for a skill's scripts:

1. **Scope to the skill directory** — use the skill's path, not a blanket `.ps1` pattern
2. **Anchor with `^`** — prevents partial matches
3. **Use the object format** — `{"approve": true, "matchCommandLine": true}`
4. **Cover subcommands** — if a script internally calls `docker`, `dotnet`, or other tools, add those patterns too or they will still prompt

### How to Find What Needs Approving

Run the full skill workflow once and note every command that prompted for approval. Each one needs its own pattern (or should be covered by a broader existing pattern).

---

## Step 5 — Verify

After saving `settings.json`, the `chat.tools.terminal.autoApprove` setting appears to hot-reload — a window reload is not required.

To verify a pattern is working, **do not re-run the script that triggered the approval** — scripts can have side effects (database changes, file writes, network calls). Instead, verify by inspection:

1. Open `settings.json` and confirm the entry is present and syntactically valid JSON
2. Wait for the next natural invocation of that command during a real workflow run
3. If you need to test immediately, construct a harmless `echo` or `Write-Host` command that starts with the same prefix as the pattern

---

## Lessons Learned

When this workflow is complete, proceed directly into the lessons learned reflection without asking permission. Follow the two-tier feedback loop from the `lessons-learned` skill:

- **Codebase findings** (specific commands that needed approval, path quirks, project-specific patterns) → write to `LessonsLearned.md`
- **Process findings** (pattern format gotchas, VS Code version behavior changes, matching engine quirks) → write to `LessonsLearned.GLOBAL.md`

Both files are at `skills/vscode-terminal-auto-approve/`.
