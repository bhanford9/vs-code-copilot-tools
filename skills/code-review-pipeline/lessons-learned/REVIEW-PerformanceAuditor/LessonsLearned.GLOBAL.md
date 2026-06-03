# LessonsLearned.GLOBAL — REVIEW-PerformanceAuditor

## Lesson 001 — Audit Tables: Single-Column Index Satisfies the Filter but Not the Sort

**Date:** 2026-05-31
**Category**: Process/Model

Audit and event-log tables almost always have query patterns of the form:
`WHERE entity_id = @id ORDER BY timestamp`. A single-column index on `entity_id`
satisfies the filter predicate but forces a separate sort step on the filtered rows
(O(k log k)). A composite index `(entity_id, timestamp)` allows an ordered index scan
that eliminates the sort entirely (O(k)).

**Rule:** When a changeset introduces an audit or event-log table with single-column
filter indexes AND query methods that always `OrderBy(timestamp)`, flag a missing
composite `(filter_column, timestamp)` index as Medium — not as "NFR-05 met." The
NFR is met for filter coverage but not for ordered scan efficiency. Check whether each
declared index's leading column matches the WHERE clause and its trailing column matches
the ORDER BY before concluding index coverage is sufficient.

---

## Lesson 002 — Single-Record Audit Write Interface → N+1 Pattern in Batch Callers

**Date:** 2026-05-31
**Category**: Process/Model

When an audit service exposes only a single-record write method (i.e., one
`WriteAsync(record)` call that commits immediately), any caller that must emit N related
records in one operation will exhibit N+1 `SaveChanges`/`commit` calls. This is a
predictable, structural consequence of the interface design — not a bug at the call site.

**Rule:** When auditing a service that calls a single-record write method in a loop,
always compute the total round-trips (loop iterations + 1 for the primary mutation).
Flag as Medium when N is bounded but variable and unbounded-in-practice. The correct
fix is a batch write method on the audit service interface, not a refactor at the caller.
Separately note the partial-audit-trail risk (records K+1..N silently absent when K
succeeded and K+1 failed) as a correctness concern, not just a performance concern.

---

## Lesson 003 — BCrypt Auditing: Two Calibrated Non-Findings

**Date:** 2026-05-29
**Category**: Process/Model

**Work factor calibration**: Work factor 12 is the current industry standard (~300 ms on 2024-era hardware). Do NOT flag the work factor itself as a performance concern unless it deviates significantly from 12 (too low = weak security, too high = DoS amplifier). When BCrypt is present at WF 10–13, mark calibration as "Correct" in the report and redirect the finding to rate limiting coverage.

**Static `_dummyHash` initialization**: A `static readonly` BCrypt hash computed at type-initialization time is the correct pattern for constant-time verification guards. The performance concern is not the pattern itself but when type initialization happens. If the service is scoped (not singleton, not warmed at startup), the first request pays double BCrypt cost. Flag as Medium, not Low — it affects every production restart.

---

## Lesson 004 — `.Include()` for PK-only Return Is a Medium Over-Fetch

**Date:** 2026-05-29
**Category**: Process/Model

When EF Core code uses `.Include(e => e.NavProp).FirstOrDefaultAsync(...)` and then only reads `e.NavProp.Id`, it is always over-fetching. The correct pattern is `.Select(e => (Guid?)e.NavPropId).FirstOrDefaultAsync(ct)`. Flag as Medium when the over-fetched path is a login hot path; flag as Low when it is a low-frequency admin path.

---

## Lesson 005 — Null `JsonSerializerOptions` Is the Correct Default Pattern — Do Not Flag

**Date:** 2026-05-30
**Category**: Process/Model

`JsonSerializer.Serialize(v, (JsonSerializerOptions?)null)` resolves to the framework's
internal cached default options singleton. It does NOT allocate a new `JsonSerializerOptions`
per call. This is the recommended pattern for default serialization. Do not flag it as
a performance concern.

---

## Lesson 007 — C# `const string` Concatenation in Method Bodies Is a Compile-Time Non-Finding

**Date:** 2026-06-02
**Category:** Process/Model

When a `const string` field is concatenated with a string literal inside a method body
(e.g., `constField + "/"` in a `StartsWith` call), the C# compiler (Roslyn) evaluates
this as a constant expression at compile time (ECMA-334 §7.19). No runtime string
allocation occurs. Do NOT flag this pattern as a heap allocation or GC pressure finding.

The compile-time rule applies when BOTH operands are constant strings. If either operand
is a non-const variable, the concatenation reverts to a runtime operation and is a valid
finding. Verify which case applies before raising the issue.

---

## Lesson 006 — New JSONB Column: Check Query Filter Scope Before Flagging Missing Index

**Date:** 2026-05-30
**Category**: Process/Model

When a changeset adds a JSONB column to an existing entity, the first index question is:
"Does any query WHERE or JOIN on this column?" If the column is only SELECTed (loaded as
part of a full entity fetch), a GIN or GiST index on it provides zero benefit. Flag a
missing JSONB index only when you find a query filtering on the JSONB content.

---

## Lesson 007 — IDOR Guard Reusing an Existing Entity Fetch Adds Zero DB Round-Trips

**Date:** 2026-05-31
**Category**: Process/Model

When an IDOR guard pattern uses `FindAsync` (or equivalent PK-based single-entity lookup)
and the fetched entity is also consumed by subsequent logic in the same method, the guard
adds _zero_ additional DB round-trips. The ownership check is an in-memory field comparison
appended to a fetch that was already required.

**Do NOT flag this as a "fetch-then-check" inefficiency.** A genuine over-fetch concern
requires both conditions to be true:
1. The entity is fetched solely for the ownership check (not needed afterward)
2. A cheaper projection query targeting only the ownership fields could replace it

If the entity is needed downstream (e.g., for change-tracking before `Remove()`, or for a
`Permissions` property read), the full `FindAsync` is the optimal choice. A projection would
require a second query to reload the entity, turning one round-trip into two.

**Additional positive**: An IDOR guard that fires before downstream DB queries (assignee
fetches, mutation queries) makes the mismatch path cheaper than the success path — the guard
eliminates subsequent queries on invalid requests. This is worth noting as a positive finding.

---

## Lesson 008 — `static readonly HashSet<string>(StringComparer.Ordinal)` Is the Reference-Correct Pattern — Do Not Flag

**Date:** 2026-05-30
**Category**: Process/Model

A `public static readonly IReadOnlySet<string>` backed by a `new HashSet<string>(StringComparer.Ordinal)` field initializer is the canonical pattern for an immutable string catalog in .NET. It is:
- Initialized exactly once per AppDomain at type-load time
- O(1) lookup
- The fastest available string comparer for ASCII identifiers with no culture/case concerns

Do NOT flag this as a performance concern. Do NOT suggest `Lazy<T>`, a static constructor, or any other deferred-initialization pattern — they provide no benefit for a small, always-needed catalog. Mark as "Correct" and move on.

**Rule:** `static readonly HashSet<string>(StringComparer.Ordinal)` for a permission/constant catalog is a positive pattern, not a finding.

---

## Lesson 009 — LINQ `FirstOrDefault` on `IReadOnlyList<T>` Creates a Closure — Flag as Low, Not Medium

**Date:** 2026-05-30
**Category**: Process/Model

When a method calls `.FirstOrDefault(predicate)` on a property typed as `IReadOnlyList<T>`:
1. It allocates a delegate (closure, since it captures a local or field)
2. It allocates an `IEnumerator<T>` through the interface (boxes the struct enumerator)

This is a Low finding, not Medium, because:
- The collection involved is invariably small (per-request, per-user data, ≤5 items)
- The total allocation is 2 small short-lived objects per call
- It is never on a hot path in authorization evaluators (multiple preceding short-circuit steps)

The correct recommendation is a manual `foreach` with an early `break`, which eliminates the closure regardless of whether struct-enumerator devirtualization applies.

**Rule:** Flag LINQ closures on small `IReadOnlyList<T>` collections as Low. Do not escalate to Medium unless the collection is unbounded or the step is documented as a hot path.

---

## Lesson 010 — `IReadOnlyList<T>` for a Whitelist Is a Medium Design Finding, Not a Low

**Date:** 2026-05-30
**Category**: Process/Model

When a whitelist property (used exclusively for membership checks) is typed as `IReadOnlyList<T>`,
the `Contains()` call resolves to the O(n) `IEnumerable<T>` extension. The semantically correct
type is `IReadOnlySet<T>` (O(1) Contains, no duplicates). Check if the same file already uses
`IReadOnlySet<T>` elsewhere for the same purpose. If it does, the asymmetry is
a clear inconsistency and justifies at least a Medium finding.

**Rule:** For any collection typed as `IReadOnlyList<T>` where the only operation is `.Contains()`,
flag as Medium if (a) the collection is unbounded by validation or (b) the same file uses
`IReadOnlySet<T>` elsewhere.

---

## Lesson 011 — List Capacity Hint `* 2` Is a Low Finding When Per-Item Output Count Varies

**Date:** 2026-05-30
**Category**: Process/Model

A projector that uses `new List<T>(items.Count * 2)` as a capacity hint is a recurring pattern.
The `* 2` heuristic is correct only when each item produces exactly 2 projected entries on average.
When the number of entries per item varies across a wide range, the hint under-allocates for medium-to-large inputs.

**Rule:** Flag `* N` capacity hints as Low when the per-item output count is variable and bounded
by a documented maximum that is significantly higher than N. Suggest an exact-capacity pre-scan
or a more conservative multiplier. Do not escalate to Medium unless the projector is confirmed
to be on a hot path (e.g., called per-request for a large user base).

---

## Lesson 012 — `Task.Run` for Synchronous CPU Work in Async Methods

**Date:** 2026-05-29
**Category**: Process/Model

Synchronous CPU-bound work inside `async` methods (e.g., BCrypt, Argon2, heavy computation) blocks thread-pool threads during execution. Best practice in ASP.NET Core is to wrap in `Task.Run()` to signal explicit CPU-bound intent. This is Medium severity, not Low — it affects thread pool behavior under burst load.

**Context:** In ASP.NET Core minimal APIs, `ConfigureAwait(false)` is not needed (no SynchronizationContext). But `Task.Run` for CPU-bound work still matters for thread pool scheduling.
