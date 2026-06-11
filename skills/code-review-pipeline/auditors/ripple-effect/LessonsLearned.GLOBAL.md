# Lessons Learned: REVIEW-RippleEffectAuditor

> GLOBAL FILE. Abstract patterns only — no class names, file paths, or project-specific identifiers.

---

## When to Append

Only append if the session revealed a non-obvious ripple detection heuristic or a false-positive risk. Skip if the review ran smoothly.

---

### New UI-facing data column without a paired seeder/fixture helper
When a new field is added to a data model that is displayed in the UI, verify that test seeder helpers and test data builders also populate the new field. A field with no seed data produces empty/null values in all test scenarios, masking rendering bugs and nullability errors.

---

### INCOMPLETE or TODO remarks without a registered follow-up: treat as an untracked delivery gap
When a code comment contains `INCOMPLETE`, `TODO`, `HACK`, or similar markers, and no linked task or work item is referenced, the gap is invisible to project tracking. Rate Medium when the incomplete section is on a code path that is reachable in the current release. The fix is to link the comment to a tracking item or resolve it before merge.

---

### Partial guard coverage on interface write paths: new method bypasses existing guards
When a service interface has multiple write methods and some are guarded (ownership check, permission check) but others are not, adding a new write method without adding the guard creates an unguarded write path. Always enumerate all write methods on the interface and verify each has consistent guard coverage.

---

### Moq mock signature changes are silent at the mock declaration site
When a mocked method's signature changes (parameter added, removed, or reordered), Moq mock setups often compile without error — especially when `It.IsAny<T>()` is used. The mock will silently match nothing (no-call path) or match incorrectly. After any method signature change, grep all test files for the old method name to find unupdated mock setups.

---

### "Known Limitations" tables in architecture docs function as delivery tracking contracts
When an architecture document contains a "Known Limitations" or "Not Yet Implemented" section, each row is an implicit delivery contract. When a feature is delivered, the corresponding row must be removed or updated in the same changeset. A stale "not yet implemented" row for a live feature is a High finding when the row covers a security surface — it misleads future developers and agents into believing the feature does not exist.

---

### Process documents that describe a workflow often have companion reference documents
When a changeset modifies a workflow (new step, removed step, changed behavior), check whether a companion document (runbook, setup guide, architecture reference) describes the same workflow. Updating code without updating the companion document creates a split source of truth. Rate Medium.

---

### Bug fix without a companion regression test: the bug will recur
When a bug is confirmed and fixed, a test must be added that would have caught the bug before the fix. The absence of a regression test means the bug can be silently reintroduced by any refactor. Rate Medium for functional bugs; High for security or data-corruption bugs.

---

### Deferred scenario notes function as forward delivery contracts
When a commit notes "this scenario is intentionally deferred to feature X," that note creates a traceable delivery expectation. When feature X ships, the deferred scenario must be addressed. Track deferred notes explicitly — they are not optional observations.

---

### Deleted test without a mirror replacement documents a regression guard gap
When a test is deleted (as part of refactoring, scenario consolidation, or cleanup), verify that the behavior the test was covering is covered by another test. A deleted test with no replacement removes a regression guard. Rate Medium; rate High if the deleted test covered a security invariant.

---

### Factory method addition without a dispatcher update: the new type is unreachable by construction
When a factory can produce a new type but the dispatcher/router that consumes factory output has no handler for that type, the new type is silently dropped or falls into a default branch. Rate High when the type falls into a "no-op" or "ignore" branch. The diagnostic signal is a factory type that does not appear in any downstream switch or handler registration.

---

### Batch Transient→Singleton promotion silently creates captive dependencies
When a commit promotes a group of services (e.g., all flow steps) from Transient to Singleton in bulk, their direct Transient dependencies become captured for the process lifetime even though they remain registered as Transient. The DI container does not warn about Transient-in-Singleton captures (only Scoped-in-Singleton). Check the `RegisterDesignLogicModules` (or equivalent utility-registration method) for Transient services that the now-Singleton consumers inject — and verify whether those services have mutable instance state. If stateless: rate Low (structural inconsistency, not a functional bug); if stateful: rate High (shared state across concurrent calls).

---

### Event log / status enum split: persisted enum values and display enum values must change in sync
When a domain status is represented by one enum for persistence (stored in the database) and a different enum for display (shown in the UI), adding a new status requires changes to both enums, the mapping between them, and any filter that operates on either. Verify all three are updated in the same changeset.

---

### Service method without a backing entity field: state is computed but not persisted
When a service method computes and returns a derived state but no corresponding column or field is persisted to storage, the computed state is re-derived on every call. Verify whether the computation is deterministic and cheap (no finding) or expensive and non-deterministic (High — the result may diverge between calls if underlying data changes mid-session).

---

### Orphaned enum: type declared without entity reference means it will never be used correctly
When an enum value is declared in one component but the record type that would be associated with it is never updated to reference or hold that value, the enum value is effectively dead. Rate Medium. The fix is either adding the reference field or removing the orphaned enum value.

---

### God interface deletion leaves architecture docs with stale type references
When a god interface (40+ members, named after the wide concern it covers) is deleted and replaced by a set of focused per-flow interfaces, architecture documents that list the god interface by name become stale. The document will still name the deleted type as a first-class design concept. Rate Medium. Always check the codebase's architecture/docs directory after any large interface deletion for named references.

---

### Batch Singleton promotion creates captive dependencies for direct-dependency Transient services
When a batch of consumers is promoted from Transient to Singleton, any Transient service they directly inject becomes captive. The correct follow-up action is to also promote those captured Transient services (if stateless) in the same or an immediately-following commit. When reviewing a Singleton-promotion commit: (1) use the captive-deps pre-scan script output if available; (2) enumerate captured Transient types; (3) verify each is stateless; (4) flag the ones that were not co-promoted as a SymmetricPath ripple gap.

---

### Agent output with no storage destination: results are ephemeral and unverifiable
When a process, background service, or agent computes a result but has no mechanism to store or report it (no log, no event, no persistent field), the output is invisible to future requests, debugging, and auditing. Rate Medium when the computation is non-trivial; High when the output is a security or compliance artifact.

---

### Incomplete Singleton promotion: captive dependencies are silent in .NET DI
When a PR promotes a batch of services from Transient to Singleton, check that all consumed dependencies of the newly promoted Singletons were also promoted. .NET DI does not warn about Transient-captured-in-Singleton (only Scoped-in-Singleton is flagged by `ValidateScopes`), so the captive dependency is invisible at startup. Rate Medium when the captured services are currently stateless; rate High if any captured service has mutable fields or inherits from a class that does. The fix is always to also promote the dependency to Singleton.

---

### Architecture docs that describe design patterns become stale when the pattern changes
When a changeset removes or replaces a named design pattern (e.g., "factory-style providers that create new instances per call" → "Singleton property-bags injected by DI"), check architecture overview docs that describe the pattern at the behavioral level. These companion docs are often missed because they describe *how* things work rather than *what* exists — so they never fail compile checks and are easy to overlook. If the overview doc names deleted interface types or uses language specific to the old pattern's mechanics, flag it as a Medium CompanionLogic finding.

---

### Dual authority schema: two services allowed to modify the same field creates a conflict surface
When two different services or workflows can both update the same entity field through separate code paths, any coordination failure produces an inconsistent state. Rate High when the two paths have no transactional coordination; rate Medium when one path is read-only in practice but not enforced.

---

### Write-only fields: timestamp stored but never read back are a maintenance trap
When an entity field is written (e.g., a `LastModifiedAt` timestamp set on every save) but never read by any query, UI, or logic path, the field costs storage and write overhead for zero value. Rate Low as an observation; rate Medium if the field's absence from the read path suggests an incomplete feature (the timestamp was added for a planned "last modified" display that was never wired).
