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

---

### Null-suppressed property returns (`null!`) are a testability hazard to check for
When reviewing provider or factory classes, scan all interface properties for `null!` (null-forgiving) returns that are gated on runtime state (toggles, flags, config). These are testability hazards: any test exercising the property under the "off" condition receives a null reference rather than a meaningful value, silently undermining test correctness. Flag any `null!`-returning property that depends on mutable/injectable state as a testability issue, even if it doesn't yet crash in production.

---

### Cascade-check concrete constructor dependencies — child/helper classes may inherit untestability
When evaluating DI dimension, do not stop at the directly-changed class. For every child, helper, or tree-node class that takes a concrete parent/owner as a constructor argument, check whether that parent pulls in UI framework objects (Dispatcher, Timer, etc.). A child class that looks trivially testable in isolation may be completely unreachable in tests because constructing it requires the parent, which requires a live framework context. Add a workflow step: for each new class whose constructor accepts a concrete (non-interface) dependency, trace the dependency chain at least one level to confirm testability is not transitively blocked.

---

### Two-level check for concrete implementations of interfaces: caller testability vs. class testability
When a new concrete class implements an interface and all its callers inject it via that interface, evaluate testability at two distinct levels: (1) **caller testability** — all callers can mock the interface, so this dimension is typically Clean; (2) **concrete class testability** — the class itself may have non-injectable IO or environment dependencies that force integration-test style testing for any test of the concrete class directly. Report these as separate concerns and use 🟡 (not 🟠/🔴) when only the concrete class is affected and callers are fully protected by the interface.
