# Lessons Learned: REVIEW-RippleEffectAuditor

> GLOBAL FILE — workflow process improvements only.
> **Recording rule**: Record only missing workflow steps, new checklist items, tool-use rules, or process sequencing discoveries that apply to any review of any codebase. No codebase-specific observations, false-positive suppressions, code patterns, or finding calibrations.

---

## When to Append

Only append if the session revealed a missing audit step or process rule that would have made this type of audit more accurate or efficient in any future review.

---
### `build-symbol-index.ps1` absent — fall back to `vscode_listCodeUsages` directly
When the `build-symbol-index.ps1` script is absent from the reviewed repo's `.claude/skills/` directory, do not fail the audit. Fall back to using `vscode_listCodeUsages` directly for symbol resolution. The script is an optimization, not a requirement.

---

### Sealed-keyword-only changesets: ripple analysis surface is zero when DI uses interfaces
When a changeset consists entirely of adding `sealed` to concrete implementation classes, and all DI registrations use interfaces (not concrete types), the ripple-effect analysis surface is zero. Mark all ripple dimensions as Clean without deep investigation.

---

### Feature status documentation may have multiple write sites — verify all are updated
When verifying that a feature completion event is documented, check ALL canonical write sites for that event. A changeset that updates one site but misses a companion site leaves the documentation partially stale. Treat this as a Medium finding.

---

### Grep for deleted config keys: exclude `**/bin/**` paths to avoid build-artifact noise
When searching for remaining references to a deleted configuration key (e.g., a feature toggle name in JSON files), always exclude `**/bin/**` and `**/obj/**` from the search pattern, or post-filter results. Build output directories always contain stale copies of config files; hits there are never a real finding. Use `includePattern` scoped to source directories (e.g., `Source/RemoteServices/**/*.json`) rather than `**/*.json` to avoid this noise.
