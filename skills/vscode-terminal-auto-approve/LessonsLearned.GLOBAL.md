# Lessons Learned (Global): vscode-terminal-auto-approve

> This file contains process/model observations applicable to any user of this skill.
> Read it before starting a session. Update it only for `Category: Process/Model` findings.
>
> For workspace-specific discoveries (specific commands, project paths, skill-specific patterns),
> write to `LessonsLearned.md` (gitignored, local to your workspace).

---

<!-- Add new entries below this line as they are discovered -->

## `&` Operator Commands Require `matchCommandLine: true` (2026-04-24)

`Category: Process/Model`

Commands that use the PowerShell call operator (`&`) — e.g. `& "d:\...\script.ps1" -Param value` — are not recognized by VS Code's subcommand parser. In the default matching mode, these commands never match any pattern, even with a correct regex and a `true` value.

**Root cause:** VS Code's default mode parses individual subcommands (using PowerShell/bash tree-sitter grammars). `&` is not parsed as a standard subcommand, so the whole command is invisible to pattern matching.

**Fix:** Use `matchCommandLine: true` in the object form to match the full raw command string instead of parsed subcommands:

```jsonc
"/^& \".*\\.github\\\\skills\\\\.*\\.ps1\"/": {
  "approve": true,
  "matchCommandLine": true
}
```

Note: per the official docs, `"/regex/": true` IS valid syntax and works correctly for standard subcommand matching. The object form is only required when you need full command line matching.
