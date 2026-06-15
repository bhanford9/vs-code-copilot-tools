# Lessons Learned: REVIEW-TestabilityAuditor

> GLOBAL FILE — workflow process improvements only.
> **Recording rule**: Record only missing workflow steps, new checklist items, tool-use rules, or process sequencing discoveries that apply to any review of any codebase. No codebase-specific observations, false-positive suppressions, code patterns, or finding calibrations.

---

## When to Append

Only append if the session revealed a missing audit step or process rule that would have made this type of audit more accurate or efficient in any future review.

---
### `TimeProvider` partial adoption: scan for direct clock calls in services that don't inject it
When a codebase has adopted `TimeProvider` for dependency-injected clock access, check every time-sensitive service in the same layer for `DateTime.UtcNow` or `DateTime.Now` direct calls. Partial adoption leaves clock dependencies untestable in the services that were missed.

---

### Sealed-keyword-only changesets: testability verdict is always Clean
When a changeset consists entirely of adding `sealed` to concrete implementation classes in an interface-driven DI architecture, the testability verdict is Clean. Sealed concrete classes in this pattern do not affect injection seams — all tests mock through the interface.

---

### Toggle-promotion changesets are net-positive for testability
When a toggle-promotion changeset simplifies a class by removing `IToggles` constructor injection that was only used for one deprecated toggle, the testability verdict is net-positive. A simpler constructor with fewer dependencies improves testability. Do not flag as a testability concern.
