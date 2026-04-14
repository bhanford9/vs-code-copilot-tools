# Code Review Pipeline — Lessons Learned

Accumulated knowledge from completed code review sessions. Append a new entry after each review using the template at the bottom.

---

## Session: 2026-04-13 — Initial creation

### Recurring Patterns Found
(none yet — first session)

### False Positives
(none recorded)

### Missing Coverage Areas
(none identified yet)

### Model Performance Notes
(baseline session — no performance data yet)

---

## Session: 2026-04-14 — AB#36345 CrossSectionalArea / Migration_5

### Recurring Patterns Found
- **Migration plugin `Initialize` + `null!` pattern**: All migrations in this codebase use `void Initialize(IServiceProvider)` mandated by `IMigration`. This is a framework constraint, not a design defect — do not flag it as a design flaw. The correct mitigation is exposing transformation logic as `internal static` methods, which this project does.
- **`internal static` extraction for testability in migrations**: The codebase deliberately exposes core migration logic as `internal static` methods with `Func<>` parameter injection. Tests call these directly. This is intentional and should be recognized as a positive pattern, not a workaround.
- **`GetDesignsToMigrateQueryForTests()` naming convention**: SQL query strings are exposed as `internal static` methods ending in `ForTests` so unit tests can assert SQL structure without executing against a real database. Check if similar extraction should be applied to other query methods in the same class.

### False Positives
- `MigrationUtils` direct instantiation in `Initialize`: Looks like a hidden dependency issue, but it is the established pattern across all migrations (e.g., `Migration_4`). Flag as medium rather than high; do not recommend DI for `MigrationUtils` unless the migration framework is being refactored.

### Missing Coverage Areas
- Private exception-swallowing methods (e.g., `TryGetSectionScalarsFromInventory`): Flag that they are untestable in isolation when the `Initialize` pattern is in use. Note the connection to any correctness finding about silent failures.

### Model Performance Notes
- Understanding `IMigration` interface contract requires reading the interface file and `MigrationRunner.cs` — don't assess the two-phase lifecycle as a fresh design smell without verifying the existing convention.
- Always read the existing `Migration_4.cs` peer implementation before auditing `Migration_5.cs` to understand what is pre-existing convention vs. what is new.

---

## Session: 2026-04-14 — AB#36345 CrossSectionalArea / Migration_5

### Recurring Patterns Found
- **"ForTests" suffix on production methods**: migration tools expose SQL strings via `internal static` for testability — but naming them `GetXxxQueryForTests()` misleads by implying test-only use. Flag any production method named with a test-qualifier suffix.
- **Positional record structs with all-same-type fields**: when a `record struct` has 4+ parameters of the same type (e.g., all `double`), flag the construction call site for named arguments.
- **`== 0d` as sentinel**: floating-point equality to zero is correct when zero is a MessagePack default (absent field sentinel), but requires a comment. Flag undocumented `== 0.0` / `== 0d` comparisons in migration/serialization contexts.
- **Naming divergence between sibling interfaces**: `ISectionMaterialFactory.Create` used `double?` while `IPositionedSectionMaterialFactory.Create` used `Area`. Cross-check sibling factory interfaces for parameter type/name consistency.

### False Positives
- **Migration_5 SRP**: identified multi-responsibility but Migration_4 establishes the same pattern. Not a true violation in this codebase context — migrations are intentionally self-contained. Flag but don't escalate beyond Medium.

### Missing Coverage Areas
- **bash/cmd script exit codes**: validated-joists-tests.cmd lost its explicit `exit /b 0` — this kind of CI script concern should be part of the maintainability checklist for `.cmd`/`.sh` files.

### Model Performance Notes
- Requirements and correctness audits flagged most of the same issues (silent exception, magic number, method name inaccuracy). Maintainability audit added value in: lambda nesting extraction, positional-record named-args, `double?` vs `Area?` inconsistency, and the `MergeScalarWithFallback` symmetry suggestion.

---

## Session: 2026-04-14 — AB#36345 CrossSectionalArea / Migration_5

### Recurring Patterns Found
- **Per-design SQL in migration tools**: `GetMaterialAreaLookupAsync` called inside a per-design loop confirmed by reading `MigrationRunner.cs`. Always check the orchestrator (runner) when auditing a migration method — the method's signature alone does not reveal call frequency.
- **Unconditional collection copy in transform methods**: LINQ `.Select(...).ToList()` in migration transforms creates new lists for every item, including those requiring no change. Short-circuit with `.Any(predicate)` before materializing.
- **`GetSerializationOptions()` as instance method vs. static field**: MessagePack / JSON serializer options that are immutable should be `static readonly` fields. Repeated construction creates GC pressure in migration loops.

### False Positives
- `HasAllSerializedSectionMaterialScalars` — initially looked like 7 × N lookups in a hot path. After confirming short-circuit evaluation (first `is not null` fails fast for V5 records) and that dictionary lookup with enum keys is O(1), this is not a real issue. Do not flag short-circuiting boolean chains over bounded constant-count dictionary lookups.
- Mapster `.Adapt<>` in `SerializeSectionMaterials` — confirmed the `TypeAdapterConfig` is passed in and shared. No re-initialization per call. Do not flag Mapster mapping overhead without first confirming whether the config is shared or rebuilt.

### Missing Coverage Areas
- **Index verification**: The performance audit cannot confirm whether `JoistAnalysisResults.DataVersion` is indexed without schema access. Future audits should note when a recommended index cannot be verified and suggest the operator run `SHOW INDEXES` / `sp_helpindex`.

### Model Performance Notes
- Reading `MigrationRunner.cs` is essential before auditing any `IMigration` implementation — the runner determines actual call frequency and concurrency model.
- Prior audits (requirements, correctness) identified the per-design SQL issue; confirming it from the orchestrator code strengthens the finding from "suspected" to "confirmed" and allows accurate scale calculations.

---

## Session: 2026-04-14 — AB#36345 CrossSectionalArea / Migration_5 (Final Synthesis)

### Recurring Patterns Found
- **Write-path test assertion gap pattern**: When forward-mapping tests use shared assertion helpers, always verify those helpers assert the *new* fields — not just that the mapping ran. A helper that checks 10 existing fields but not the 11th new field provides false confidence. Flag this explicitly during unit-test coverage audits.
- **`ForTests` suffix on public-facing extraction methods**: Methods like `GetDesignsToMigrateQueryForTests` and `GetMaterialAreaLookupQueryForTests` are intentionally exposed for SQL text assertions in unit tests — but the `ForTests` name misleads when the method is also called by production code. Rule: if a method is called from a production path, it must not have a test-qualifier suffix regardless of why it was made accessible.
- **Cross-audit confirmation strengthens severity**: Issues flagged by 3+ independent auditors should be promoted to "high priority" in the final report even if individual auditors rated them medium. The per-design SQL was Medium (Correctness), High (Performance), and High (Extensibility) — final report correctly rated it High overall.
- **Lazy `??=` is the minimal-impact fix for one-time async initialization**: When `IMigration.Initialize` is synchronous and a migration needs a one-time async DB call, a `private X? _field; async Task M() { _field ??= await ...; }` pattern avoids interface changes and is safe under the sequential single-threaded MigrationRunner call model.

### False Positives
- **13-parameter factory overload untested** — the unit test coverage auditor correctly flagged this, but context shows the overload is only reachable through end-to-end mapper tests (which do cover it via integration). Flag as Medium rather than High when the method is exercised by higher-level tests even if no direct unit test exists.

### Missing Coverage Areas
- **Script exit code auditing**: `.cmd` and `.sh` scripts in the repository should be checked for explicit `exit /b 0` (cmd) or `exit 0` (bash) on success paths. Missing exit codes can cause CI to misreport success.
- **Forward-mapping write path is a systematic blind spot**: In this codebase, read-path tests tend to assert domain object values (easy to verify via typed properties). Write-path tests tend to assert which mock methods were called but not what was serialized (hard to verify in the raw field dictionary). Future reviews should explicitly check whether serialization output field dictionaries are asserted.

### Model Performance Notes
- When synthesizing, group findings by "consistent theme" rather than "consistent severity." Three auditors flagging the same method at different severities is stronger evidence than one auditor flagging it at Critical.
- The Final Synthesizer should not re-read all source files — it should rely entirely on the 7 audit reports plus lessons learned. If a finding needs verification, that is evidence the parallel audits were incomplete.

---

## Session: 2026-04-14 — AB#36345 CrossSectionalArea / Migration_5

### Recurring Patterns Found
- **Parameter-list explosion** is a signal pattern: when a factory interface grows beyond 9 parameters, a value-object refactor is typically overdue. Look for `Create(...)` overloads where consecutive parameters share the same type.
- **Synchronous lifecycle methods on async-dependent implementations** (e.g., `void Initialize`) predictably cause per-call redundant work when the implementation needs async setup. Check migration/lifecycle interfaces for `void` methods that implementors need to be `async`.
- **Manual guard functions tied to enum ranges** (e.g., `HasAllSerializedSectionMaterialScalars`) have no compile-time enforcement and require a corresponding unit test to catch omissions; the omission was real in this PR.

### False Positives
(none recorded this session)

### Missing Coverage Areas
- The `ConvertToFieldData` / `ConvertFromFieldData` switch structures in DescriptionMapper are a pre-existing OCP violation. Flagged as out of scope for this PR but worth noting in future reviews of that file.

### Model Performance Notes
- Prior audits (requirements, correctness) provided excellent context; reading them first eliminated significant re-analysis work. The High/Medium/Low structure from prior audits mapped cleanly onto extensibility dimensions.

---

## Session: 2026-04-14 — AB#36345 CrossSectionalArea / Migration_5

### Recurring Patterns Found
- **Write-path assertion helpers not updated for new fields**: When new scalar fields are added to a forward-mapping path, the corresponding `AssertThat*DescriptionsAreEqualForKeyValueData` helper methods are often not extended to assert the new fields. This is a systematic gap whenever the DescriptionMapper gains new FieldType entries.
- **New factory overloads missing direct unit tests**: When an existing factory interface gains a new overload (PositionedSectionMaterialFactory gained a 13-param overload), the factory test file may only have tests for the original 2-param overload with no test for the new overload added.
- **Modified legacy overload (e.g., `Create(IMaterial)`) not re-tested**: When an existing method is modified to thread a new property through its constructor call, no new test is added to confirm the new property arrives correctly. The old test that verified calculator delegation was deleted or renamed without adding a `CrossSectionalArea` assertion.

### False Positives
(none recorded)

### Missing Coverage Areas
- Forward-mapping (write-path) scalar assertions in DescriptionMapperTests — check `AssertThat*DescriptionsAreEqualForKeyValueData` helpers for every PR that adds new FJA fields
- Factory overload tests when interface grows

### Model Performance Notes
- The Migration_5 test suite was thorough and well-parameterized; the production code correctness audit held up well
- The read-path tests (reverse mapping) were comprehensive with mock verification; only write-path assertions were weak

---

<!-- TEMPLATE — copy below this line for each new session

---

## Session: {YYYY-MM-DD} — {branch or feature reviewed}

### Recurring Patterns Found
(defect patterns that appeared across multiple files or authors)

### False Positives
(auditor findings that were not real issues — note why)

### Missing Coverage Areas
(code areas the auditors should check but currently don't)

### Model Performance Notes
(which auditors were thorough vs. superficial, any prompt improvements needed)

-->
