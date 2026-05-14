# Lessons Learned: REVIEW-SecurityAuditor

> Findings specific to this auditor. Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.
>
> ⚠️ **GLOBAL FILE — NO CODEBASE-SPECIFIC CONTENT ALLOWED**
> Do NOT write: work item IDs, class names, method names, file names, test names, or any reference to a specific repo or project.
> Write ONLY: abstract patterns, heuristics, and model-behavior observations that apply to any codebase.
> When in doubt → write to `LessonsLearned.md` (gitignored, local) instead.

---

## When to Append an Entry

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future security reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## 2026-05-08 — Scope-Relative Severity for Absent Auth

**Pattern**: When a personal/local-only application has no authentication, resist classifying this as Critical/High at face value. Apply a deployment-context matrix: localhost-only = Medium; LAN-accessible = High; internet-facing = Critical. Flag it clearly with the escalation condition rather than assigning worst-case severity for a tool that is demonstrably scoped to single-user local use.

**Heuristic**: Check whether the architectural intent (personal tool, no multi-user model) is apparent from the domain model, DI registration, and README before assigning severity to missing auth.

---

## 2026-05-08 — Binary Database Files in Git

**Pattern**: Design-time or migration-scaffolding database files (SQLite `.db`, Access `.mdb`, etc.) frequently appear committed to source repositories. They are binary blobs that do not belong in git: they can accumulate real data, cause merge conflicts, and bloat history. Always check `git ls-files` for `*.db` patterns during security reviews. Classify as Medium if only schema is present, escalate if real data is detected.

---

## 2026-05-12 — CSS Injection via Inline Style Attribute with User-Controlled Color Field

**Pattern**: Color fields (hex color pickers in UI forms) that feed into inline `style="background-color: @Color"` attributes are a CSS injection vector. Blazor's HTML encoding neutralizes HTML-special characters but does NOT prevent CSS token injection (e.g., `#fff; display:none`). When auditing, always trace `color`-type fields from their origin (user input / DB) through to any `style=` attribute usage. Validate with a strict hex color regex at the service layer.

**Heuristic**: Check all `style=` attribute expressions in Razor files for any dynamic value sourced from user data. CSS injection is easily missed because the obvious XSS vectors (script tags, event handlers) are absent.

---

## 2026-05-12 — Hardcoded Fallback Connection Strings in Dev-Time Factory and CLI Bootstrap

**Pattern**: Design-time EF Core factories (`IDesignTimeDbContextFactory`) and CLI tools that bootstrap their own DI often contain hardcoded fallback connection strings so they work "out of the box" during development. These fallbacks routinely end up committed to git and can carry production-equivalent credentials if password hygiene is poor. During security reviews, always check `IDesignTimeDbContextFactory` implementations and CLI `Program.cs` bootstrap sections for `??` fallback connection strings.

**Heuristic**: Fail fast with an explicit error message when the environment variable or config is absent — do not provide a default that makes credentials optional.

---

## 2026-05-12 — `ProcessStartInfo.Arguments` vs `ArgumentList` for Subprocess Safety

**Pattern**: When a C# codebase spawns external processes with `UseShellExecute = false`, shell injection is not a risk. However, if `ProcessStartInfo(fileName, arguments)` is used with a single string `arguments`, and any segment of that string is constructed from config or user data without quoting, argument-splitting bugs can occur (spaces in values, unexpected extra args). The safe alternative is `ProcessStartInfo.ArgumentList` which passes each argument as a separate element without any quoting/parsing. Always prefer `ArgumentList` over the string `Arguments` property when constructing arguments programmatically.

---

## 2026-05-12 — Pure Internal Domain Logic: OWASP Non-Applicability Pattern

**Pattern**: For changes that are entirely within a deep-pipeline calculation engine (no network, no I/O, no external API surface, no user input crossing a trust boundary), the majority of the OWASP Top 10 is structurally non-applicable. The meaningful security question for this class of change is: "Can a flow-skip or short-circuit produce an unsafe domain output?" — not injection, access control, or cryptography.

**Heuristic**: When all inputs to a changed class are in-process domain objects set by prior trusted pipeline stages, write concise "Not applicable" explanations for each OWASP category rather than forcing speculative findings. For flow-control changes specifically, verify: (1) the skip is bounded (does not persist indefinitely), (2) a fallback path ensures correct output on subsequent iterations, and (3) unit tests cover the boundary conditions of the skip predicate.

---

## 2026-05-12 — Flow Exit Log Strings in Engineering Tools Are Not Sensitive Data

**Pattern**: Internal flow frameworks in engineering tools use descriptive string literals as exit/skip reasons. These are execution traces, not user-facing messages, and contain no sensitive data.

**Heuristic**: Do not classify these as information disclosure findings unless the framework demonstrably surfaces them externally (API response, browser, log shipped off-machine). At most, note them as Low/informational with the escalation condition.

---

## 2026-05-13 — `Path.Combine` Does Not Sanitize Inputs — Always Sanitize String Paths From Non-Literal Sources

**Pattern**: `Path.Combine(baseDir, untrustedSegment)` on .NET has two path-traversal behaviors: (1) a relative `..`-containing segment traverses above the base directory (Windows resolves `..` at the OS level during `Directory.CreateDirectory` / `File.Open`), and (2) an absolute-path segment completely discards the base directory. This applies even when the data source is "trusted" (internal DB, internal API). A string field in a database is still a string and can contain path characters if data quality is not enforced at the schema level.

**Heuristic**: Any string that is not a compile-time literal and is used in `Path.Combine` requires sanitization — strip `\`, `/`, `:`, and `..` sequences before use. Check whether the code applies the same sanitization consistently to all segments (not just some of them).

**Severity guidance**: For dev/diagnostic tools with an internal trusted data source, classify as Medium (not High), document the low practical exploitability, and provide the one-line fix. Reserve High for tools with external user input at this boundary.

---
