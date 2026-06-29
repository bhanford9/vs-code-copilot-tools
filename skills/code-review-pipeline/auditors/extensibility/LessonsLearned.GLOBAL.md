# Lessons Learned: REVIEW-ExtensibilityAuditor

> GLOBAL FILE — workflow process improvements only.
> **Recording rule**: Record only missing workflow steps, new checklist items, tool-use rules, or process sequencing discoveries that apply to any review of any codebase. No codebase-specific observations, false-positive suppressions, code patterns, or finding calibrations.

---

## When to Append

Only append if the session revealed a missing audit step or process rule that would have made this type of audit more accurate or efficient in any future review.

---
### Convergent Medium findings at a feature boundary may warrant a compound upgrade
When three or more Medium extensibility findings cluster at the same feature boundary (same interface, same class group, or same public API surface), evaluate whether they collectively constitute a single High finding. The escalation criterion: the combination creates a structural enforcement gap that none of the individual Mediums alone would justify upgrading.

---

### Toggle-promotion changesets: check for orphaned toggle injections
After confirming a toggle-promotion changeset, check every class whose toggle guard was removed for orphaned toggle-bag injections. If the removed toggle was the sole consumer of the injected toggle dependency, the constructor parameter, its backing field, and any related import become dead. This will not be caught automatically — verify each changed class explicitly.

---

### Static-interface duplication: check whether callers use the interface or bypass via static
When the changeset adds an instance method to an interface that mirrors (or delegates to) a static method on the concrete implementation, search all changed files for direct calls to the static version. A new interface method is ineffective as an extension point if all callers still reach the static directly. Flag each bypass as a DIP finding. The check is not limited to the class that changed — any caller in any changed file is a candidate.

