# Lessons Learned: REVIEW-StructuralPatternsAuditor

> GLOBAL FILE — workflow process improvements only.
> **Recording rule**: Record only missing workflow steps, new checklist items, tool-use rules, or process sequencing discoveries that apply to any review of any codebase. No codebase-specific observations, false-positive suppressions, code patterns, or finding calibrations.

---

## When to Append

Only append if the session revealed a missing audit step or process rule that would have made this type of audit more accurate or efficient in any future review.

---
### Composition-root-dominated reviews produce expected clean verdicts — do not manufacture findings
When the entire changeset consists of DI composition-root changes (new registrations, lifetime adjustments, module reorganization), expect Clean verdicts across most SP categories. Do not manufacture structural pattern findings to populate the report — a Clean verdict is the correct outcome.

---

### Toggle-promotion PRs: structural verdict is Clean — orphaned injection is the one exception
When auditing a toggle-promotion PR (feature flag permanently enabled, dual-case code removed), the structural verdict should be Clean for all SP categories EXCEPT: check for orphaned toggle-bag constructor injections in every changed class. If the removed toggle was the sole consumer of the injection, the orphaned injection is a Low finding regardless of toggle-promotion context.

---

### Additive-only property extensions: "Clean" is the correct verdict when all sibling consistency checks pass
When a changeset adds new properties to an existing record or class without changing existing properties, verify: (1) the new properties follow the naming convention of siblings, (2) any companion arrays or dictionaries that enumerate same-type properties are updated. If both checks pass, "Clean" is the correct structural verdict — do not manufacture a finding.
