# Lessons Learned: REVIEW-MaintainabilityAuditor

> GLOBAL FILE — workflow process improvements only.
> **Recording rule**: Record only missing workflow steps, new checklist items, tool-use rules, or process sequencing discoveries that apply to any review of any codebase. No codebase-specific observations, false-positive suppressions, code patterns, or finding calibrations.

---

## When to Append

Only append if the session revealed a missing audit step or process rule that would have made this type of audit more accurate or efficient in any future review.

---
### Documentation "test-verified" claims require spot-checks against the actual test suite
When documentation or a specification table claims that behaviors are "verified by tests," treat this as a verification trigger — not a fact. Cross-reference the claimed verification against the actual test file contents before accepting it.

---

### Document item-count claims should be verified before the review closes
When a document contains a claim like "the catalog contains N entries" or "there are M registered providers," verify by counting the actual code-defined entries. A stale count is a reliability signal.

---

### When a unifying private helper is added, scan for pre-existing inline occurrences of the same logic
When a refactor extracts a shared helper method, verify that all pre-existing inline occurrences of the same logic were replaced. A new helper that coexists with two remaining inline copies is worse than no helper — it creates multi-way divergence.

---

### Tripled copy-paste block: active divergence scan is required
When the same non-trivial block appears three or more times, include a divergence scan as part of the audit — not just a DRY observation. Report whether the three copies are currently in sync or have already diverged.

---

### Toggle-promotion changesets: check for orphaned toggle fields
After confirming a toggle-promotion changeset, check every class whose toggle guard was removed for orphaned toggle-bag fields. These will not be caught by automated dead-code tools because the field declaration is retained. Rate each orphaned field as Medium (Coupling).
