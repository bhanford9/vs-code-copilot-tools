# Lessons Learned: REVIEW-PerformanceAuditor

> GLOBAL FILE — workflow process improvements only.
> **Recording rule**: Record only missing workflow steps, new checklist items, tool-use rules, or process sequencing discoveries that apply to any review of any codebase. No codebase-specific observations, false-positive suppressions, code patterns, or finding calibrations.

---

## When to Append

Only append if the session revealed a missing audit step or process rule that would have made this type of audit more accurate or efficient in any future review.

---
### Feature-toggle promotion changesets: runtime behavior is always neutral for performance
When auditing a feature-toggle promotion (toggle permanently enabled, dual-case code removed), verify the toggle's prior production state via the requirements audit. If the toggle was already always-on in production, the promotion changes nothing at runtime. Mark Memory and Algorithm dimensions as Clean without deep investigation.
