# Lessons Learned: REVIEW-MaintainabilityAuditor

> GLOBAL FILE. Abstract patterns only — no class names, file paths, or project-specific identifiers.

---

## When to Append

Only append if the session revealed something surprising, a false-positive pattern, or a finding worth noting for future maintainability reviews. Skip if the review ran smoothly.

---

### Bare `Task.Delay` for "absence of X" E2E assertions is a timing-dependent false-negative risk
A test that asserts an event did NOT occur by sleeping and then checking is fragile — the event may simply not have arrived within the sleep window. Rate Medium in any codebase that injects `TimeProvider` or has a mechanism to synchronize on event completion: "waiting instead of synchronizing" is a code smell that creates CI flakiness and masks real failures. Recommend replacing with a synchronous check or an explicit wait-for-idle mechanism.

---

### Parallel array + keyed dictionary over the same domain objects: DRY violation elevated by a confirmed sync bug
When a class exposes both an ordered array and a lookup dictionary that represent the same domain concept, and a known production bug exists whose direct cause is that one structure was updated without the other, rate the DRY violation High (not Medium). The bug IS the DRY failure manifesting in production. Recommendation: derive the dictionary from the array at type-load time so there is only one source of truth.

---

### Documentation "test-verified" claims require spot-checks against the actual test suite
When documentation or a specification table claims that behaviors are "verified by tests," treat this as a verification trigger — not a fact. Cross-reference the claimed verification against the actual test file contents. A specification that claims verification but has no supporting test actively misleads future developers.

---

### Multi-class single-file test pattern that departs from convention: flag when convention is documented
When a codebase has a documented one-class-per-file test convention and a file contains multiple test classes, flag Medium. The finding is not about the pattern itself — it is about the deviation from the convention, which increases cognitive load for developers who scan by class name in solution explorer.

---

### Document item-count claims should be verified before the review closes
When a document contains a claim like "the catalog contains N entries" or "there are M registered providers," verify the claim by counting the actual code-defined entries. A stale count is a reliability signal: if the count is wrong, what else in the document is also stale?

---

### Free-text descriptor fields on append-only entities create hidden migration costs
When an entity has a free-text field (description, label, comment) that is stored but has no indexed search, no enumeration, and no downstream processing today, adding future indexing or parsing requires a migration of all historical values. Rate Low as an observation; rate Medium if the field is already populated with structured values that are being string-parsed at read time.

---

### When a unifying private helper is added, scan for pre-existing inline occurrences of the same logic
When a refactor extracts a shared helper method, verify that all pre-existing inline occurrences of the same logic were replaced. A new helper that coexists with two remaining inline copies is worse than no helper — it creates three-way divergence. Always verify the helper is exhaustively adopted.

---

### Enum value whose documented semantics require a missing context field
When an enum value's documented behavior requires knowing a context that the enclosing record or class does not store, the enum value is incomplete by design. Rate Medium — the enum communicates an intent that cannot be fully reconstructed from the data model alone. The fix is either adding the required context field or eliminating the enum value.

---

### DRY violation that replicates a known bug: rate High regardless of the violation's size
When a duplicated code block also duplicates a known bug (the same incorrect logic appears in two places), rate the DRY violation High — not Medium. The duplication means any fix to the canonical copy will miss the duplicate, leaving the bug alive. This is a higher-severity concern than a DRY violation in correct code.

---

### Framework-required public property with private naming convention: always note the constraint
When a framework requires a property to be public (e.g., for serialization, data binding, or source-generated code) but the team's convention names it as internal state (underscore prefix, lowercase), flag Low with an explanation: "public modifier required by framework, naming is a convention deviation." Do not flag as a pure maintainability concern without noting the framework constraint.

---

### Tripled copy-paste block: active divergence scan is required
When the same non-trivial block appears three or more times, the finding is not just DRY — it is a structural risk that future changes to one copy will not be applied to the others. Rate Medium and include a statement about the divergence risk, not just the duplication observation.

---

### Sole `virtual` member in an otherwise-sealed class is a test-infrastructure-bleed diagnostic signal
When a class has exactly one `virtual` member and all other members are sealed/non-virtual, the `virtual` member was almost certainly added specifically to enable mocking in tests. The correct fix is not to seal the member — it is to introduce an injectable abstraction so tests do not need to subclass the production class. Rate Low as a code smell; rate Medium if the class is security-critical (a `virtual` on a security guard method is a bypass seam).
