# Lessons Learned: REVIEW-UnitTestCoverageAuditor

> GLOBAL FILE — workflow process improvements only.
> **Recording rule**: Record only missing workflow steps, new checklist items, tool-use rules, or process sequencing discoveries that apply to any review of any codebase. No codebase-specific observations, false-positive suppressions, code patterns, or finding calibrations.

---

## When to Append

Only append if the session revealed a missing audit step or process rule that would have made this type of audit more accurate or efficient in any future review.

---
### "Met" ≠ "Tested": a requirement documented as passing does not mean the behavior is mechanically asserted
When evaluating whether a requirement is covered, verify that a test specifically asserts the stated condition — not just that the code path is exercised. A test that exercises a path but does not assert the requirement's outcome does not count as coverage.

---

### Deleted guard requires a replacement test documenting the new inclusive behavior
When a `.Where()` filter or conditional guard is removed, flag the missing replacement test as a required action. The previously-excluded inputs are by definition untested with the old code — the new inclusive behavior must be explicitly documented by a test.

---

### Zero-test subsystems: start with infrastructure assessment before itemizing gaps
When the changeset touches a subsystem with no existing tests, report the absence of test infrastructure as the primary finding. Do not itemize individual gap findings until the infrastructure finding is acknowledged — individual gaps are secondary to the structural gap.

---

### Known-gap requirements need a formally pending test
When a known gap is acknowledged and deferred, verify that a pending or ignored test exists to formally document the gap. An acknowledged gap with no test entry is invisible to future test runners.

---

### Cross-fixture gap check: verify coverage parity across related test fixtures
When one fixture tests method A but a related fixture (covering a sibling scenario) does not, flag the asymmetry. Related fixtures (e.g., create/update, insert/delete, request/response) should maintain coverage parity.

---

### Command handler output-write coverage: always assert on the write destination, not just the return value
When evaluating coverage of a command handler, verify that at least one test asserts on the destination of the write (the stored entity, the emitted event, the persisted record) — not just on the return value or the fact that the handler ran.

---

### Sealed-keyword-only commits require zero new tests
When a changeset consists entirely of adding `sealed` to implementation classes with no behavioral changes, the correct coverage verdict is Clean — zero new tests are required. Produce this verdict immediately without running coverage gap analysis.

---

### Toggle-promotion changesets: dual-case test removal is correct
When a toggle-promotion changeset removes toggle-off test cases and replaces them with single unconditional tests, this is the correct pattern — not a coverage gap. Do not flag the removal of disabled-case tests as a coverage regression.
