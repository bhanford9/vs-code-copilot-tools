# Lessons Learned: REVIEW-ExtensibilityAuditor

> Findings specific to this auditor. Updated automatically at the end of each code review session.
> Read this file at the start of each review to apply accumulated knowledge.

---

## When to Append an Entry

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future extensibility reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## Entry: C# Default Interface Members — Overrides Dispatch Correctly Through Interface References

**Date**: 2026-04-22
**Category**: Process/Model

When a C# 8+ interface uses default property/method implementations that `new` up concrete types, those defaults CAN be overridden in implementing classes — and the override WILL be called as long as the consumer holds an interface reference (not a concrete reference). Do NOT flag this pattern as "defaults are not overridable" or "tightly coupled to concrete types at the interface level" when the calling code uses the interface reference. The extension point is real and functional. Severity should not exceed Low unless the implementing class is also `sealed` and no alternative implementation path exists.

