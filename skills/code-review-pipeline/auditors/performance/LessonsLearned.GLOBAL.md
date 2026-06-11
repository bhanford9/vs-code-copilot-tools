# LessonsLearned.GLOBAL — REVIEW-PerformanceAuditor

> GLOBAL FILE. Abstract patterns only — no class names, file paths, or project-specific identifiers.

---

### Audit tables: single-column index satisfies the filter but not the sort

Audit and event-log tables almost always query `WHERE entity_id = @id ORDER BY timestamp`. A single-column index on `entity_id` satisfies the filter but forces a separate sort. A composite `(entity_id, timestamp)` index enables an ordered index scan, eliminating the sort entirely. Flag a missing composite index as Medium when single-column filter indexes AND `OrderBy(timestamp)` queries coexist in the same changeset. Check that each declared index's leading column matches the WHERE clause and its trailing column matches the ORDER BY.

---

### Single-record audit write interface → N+1 pattern in batch callers

When an audit service exposes only a single-record write method that commits immediately, any caller emitting N related records performs N+1 commit calls. This is a structural consequence of the interface design. Flag as Medium when N is variable and unbounded in practice. The correct fix is a batch write method on the audit service, not a refactor at the caller. Note separately: a partial-write failure (records K+1..N absent when K succeeded) is a correctness concern, not just a performance concern.

---

### BCrypt: two calibrated non-findings

**Work factor calibration**: Work factor 12 (~300ms on 2024 hardware) is the current standard. Do not flag it as a performance concern unless it deviates significantly from 10–13. Redirect findings to rate-limiting coverage.

**Static dummy hash initialization**: A `static readonly` BCrypt hash computed at type-initialization time is the correct pattern for constant-time verification guards. Rate Medium (not Low) if the service is scoped rather than singleton — the first request after each restart pays double BCrypt cost.

---

### `.Include()` for PK-only return is a Medium over-fetch

When an EF Core query uses `.Include(e => e.NavProp)` and only reads `e.NavProp.Id`, the include fetches the full navigation entity unnecessarily. A projection to the FK scalar is the correct pattern. Rate Medium on login/hot paths; Low on low-frequency admin paths.

---

### New JSONB column: check query filter scope before flagging missing index

When a changeset adds a JSONB column, the first index question is "does any query WHERE or JOIN on this column?" If the column is only SELECTed as part of a full entity fetch, a GIN/GiST index provides zero benefit. Flag a missing JSONB index only when a query filtering on JSONB content is found.

---

### `IReadOnlyList<T>` for a whitelist membership check is a Medium design finding

When a whitelist property is typed as `IReadOnlyList<T>` and the only operation is `.Contains()`, the call resolves to O(n) enumeration. The semantically correct type is `IReadOnlySet<T>` (O(1) Contains). Rate Medium if the collection is unbounded or the same file already uses `IReadOnlySet<T>` elsewhere for the same purpose.

---

### LINQ `FirstOrDefault` on `IReadOnlyList<T>` allocates a closure: flag Low, not Medium

Calling `.FirstOrDefault(predicate)` on a property typed as `IReadOnlyList<T>` allocates a delegate closure and an enumerator through the interface. Rate Low — the collection is invariably small and the two allocations are short-lived. The correct recommendation is a manual `foreach` with early break. Do not escalate to Medium unless the collection is unbounded or the step is documented as a hot path.

---

### List capacity hint `* N` is Low when per-item output count varies

A projector using `new List<T>(items.Count * N)` as a capacity hint under-allocates when actual output per item exceeds N. Rate Low when the per-item count varies and the documented maximum is significantly higher than N. Do not escalate to Medium unless the projector is on a confirmed hot path.

---

### DI Transient→Singleton promotion: surviving per-call builders are the residual allocation source

When a changeset promotes a large number of services from Transient to Singleton (e.g., a DI wiring refactoring), check for any **remaining Transient services that build wrapper objects per call** (e.g., a factory or runner that calls `new Builder()` / `new Runner()` on each operation). With dependencies now singleton, the wrapper's produced graph is structurally identical across calls; the residual allocations are often candidates for lazy-cache promotion. Rate Low — the promotion change itself is a net positive for allocator pressure. Do not flag the remaining per-call builders as High or Medium unless the per-call allocation is measurably significant (e.g., large collection initialization, reflection-based graph construction) or the operation is documented as a hot path.
