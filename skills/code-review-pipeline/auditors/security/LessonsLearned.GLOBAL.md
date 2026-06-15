# Lessons Learned: REVIEW-SecurityAuditor

> GLOBAL FILE — workflow process improvements only.
> **Recording rule**: Record only missing workflow steps, new checklist items, tool-use rules, or process sequencing discoveries that apply to any review of any codebase. No codebase-specific observations, false-positive suppressions, code patterns, or finding calibrations.

---

## When to Append

Only append if the session revealed a missing audit step or process rule that would have made this type of audit more accurate or efficient in any future review.

---
### Test harnesses wrapping the full DI container: verify security-relevant services are not excluded
When a test harness constructs the full DI container, check that auth middleware, ownership guards, and permission evaluators are present. Some test harnesses exclude security-related services to simplify test setup — this silently removes the security surface from coverage.

---

### Pure calculation modules: confirming OWASP non-applicability is the correct audit output
When the changeset is entirely within a pure calculation or domain model layer with no I/O, database access, or external API calls, systematically confirm each OWASP Top 10 category as "not applicable" with a one-sentence rationale. This is the complete and correct audit result — do not expand the scope to find findings where there are none.

---

### Filter removal on internal pipelines: verify it was not also a data-exposure filter
When reviewing a `.Where()` or condition filter removal (even one motivated by correctness or performance), verify that the removed filter was not also preventing unauthorized data from appearing in results. Check the full downstream data flow before closing the finding.

---

### IDOR asymmetry: always audit write paths independently from read paths
When reviewing IDOR protection, do not infer write-path protection from read-path filters. Read paths and write paths are independent code paths that each require their own ownership verification. Always audit write paths (create, update, delete) separately from read paths.
