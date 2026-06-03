# Lessons Learned (Global): code-review-pipeline

> This file contains process/model observations applicable to any user of the code-review-pipeline skill.
> Read it before starting a review session. Update it only for `Category: Process/Model` findings.
>
> For codebase-specific discoveries (recurring false positives in this codebase, project-specific patterns),
> write to `LessonsLearned.md` (gitignored, local to your workspace).

---

### Multi-record audit catch blocks: always track which write stage failed, not just the outer operation name
Category: Process/Model

When auditing code that performs multiple sequential async writes inside a single try/catch (e.g., a service that writes one header record then N detail records all under the same `CorrelationId`), check whether the catch-block error message is generic or specific. A common pattern:

```csharp
try
{
    await service.WriteAsync(headerRecord);         // Write #1 — commits immediately
    foreach (var item in items)
        await service.WriteAsync(itemRecord);       // Writes #2..N
}
catch (Exception ex)
{
    logger.LogError(ex, "Write failed for {Operation}.", "HeaderOperation"); // always says "header"
}
```

If Write #1 succeeds and Write #2 throws, the catch fires — but the log says the header operation failed when it actually succeeded. This is factually wrong and misleads operators diagnosing an incomplete record set.

**The correctness question:** "Does the catch-block message accurately reflect which write actually failed?" If the catch is outside a loop over multiple writes, the answer is often no.

**Recommended pattern:** Track the current stage in a local variable before each write; use that variable in the catch message.

---

### Information-leak prevention tests: wildcard message assertions don't prove identity — use exact-string assertions
Category: Process/Model

When verifying that two code paths produce "identical" exception messages for information-leak prevention (e.g., IDOR mismatch must be indistinguishable from not-found), check whether the tests assert the **full exact message** or only a wildcard substring. A test like `.WithMessage($"*{id}*")` passes even if one path says `"Resource {id} not found."` and the other says `"Resource {id} not found — access denied."` — the wildcard would pass both. Future refactors could silently break the no-leak guarantee without any test failure.

**The correctness question:** "Does this test fail if the two exception messages differ by even one word?" If the answer is no, the test is not covering the stated requirement.

**Recommended pattern:** Assert the complete message with `.WithMessage($"Resource {id} not found.")` (no wildcards) on at least one of the two paths. Alternatively, extract the expected string to a constant and reference it from both throw sites and the test.

---

### IDOR guard correctness: ResourceId check alone is insufficient when the resource type is polymorphic
Category: Process/Model

When reviewing an IDOR guard that checks ownership via a resource-ID field (a `Guid`), always verify whether the guard **also checks the resource type/scope** (e.g., `ScopeId == ResourceScope.Primary`). A resource-ID-only check can allow cross-scope bypass if two different scopes can share the same ID value — which is possible when GUIDs are allocated independently per scope rather than from a shared sequence.

**The correctness question:** "Can a resource with the correct owner ID but the wrong scope pass this guard?" If yes, and the write-path is scope-specific, this is a Medium gap — low probability in practice but a defense-in-depth failure.

**Common pattern:** When a feature spec says `OwnerId == X && ResourceScope == Y`, but the input packet simplifies to only `OwnerId == X`, the implementation follows the input packet. Always diff both docs and flag the discrepancy — it creates conflicting requirements for downstream auditors.

---

### Enum-scope gaps in permission systems: always check if scope enum covers all spec-defined scope names
Category: Process/Model

When auditing a permission evaluation system, check whether the scope enum (or equivalent) contains a value for every conceptual scope named in the spec. It is a common pattern for the runtime enum to have only two values (e.g., `Primary` and `Secondary`) when the spec names three scopes. The missing scope means one category of permissions shares a runtime scope with another category — providing no scope-level isolation between them. Isolation then depends entirely on permission string differences, not on enum enforcement.

**The key correctness question:** "Does the test demonstrating isolation between scope X and scope Y actually prove scope isolation, or only permission-string isolation?" If the enum has no `Y` scope, the answer is always "permission-string isolation only."

**The migration trap:** If the missing scope value is added later, all grants persisted with the wrong scope value will silently stop matching. No compile error. No test failure at migration time. Flag this during correctness audits as Medium — not a current bug, but a documented migration risk.

---

### Owner guardrail correctness: check whether scope alignment is enforced
Category: Process/Model

When auditing a permission evaluator that has an "owner guardrail" (a set of permissions always granted to owners regardless of template state), verify whether the guardrail check also validates scope alignment. A common correctness gap: the guardrail checks `OwnerGuardrailSet.Contains(context.Permission)` without also verifying `expectedScope == context.Scope`. If the guardrail set contains permissions from multiple scopes, an owner checking a guardrail permission against the wrong scope resource will incorrectly receive Allow.

**Detection:** Look for `HashSet.Contains(permission)` in the guardrail check path — if no `&& scope == expectedScope` condition follows it, the gap may be present. Severity: Medium when guardrail mixes scopes; Low when all guardrail permissions belong to a single scope.

---

### Self-referential compliance traps in agentic protocol improvements
Category: Process/Model

When a changeset introduces a new compliance rule (e.g., "status files must use exactly `completed`"), always check whether the delivery artifacts for that changeset itself comply with the rule it introduces. This is the most likely place for a violation because the rule was enforced going forward but the delivery artifacts were written before the rule was finalized.

**The correctness question:** "Does this feature's own `06-status.md`, feature-index entry, or traceability doc satisfy the invariant this feature is introducing?"

**Detection:** For every new format/string constraint added in a SKILL.md or delivery doc, read the status file at `work-planning/delivery/.../[this-feature]/06-status.md` and confirm it matches the exact string the feature mandates. The feature index may have been updated in a later commit, but `06-status.md` files are often written early and not revisited.

---

### Stale correctness-audit.md from prior session: delete-then-create is the correct recovery path
Category: Process/Model

When `code-review/correctness-audit.md` already exists from a prior review session and must be fully replaced, `create_file` will fail ("file already exists"). Using `replace_string_in_file` to replace large sections is fragile — if the old content matches only part of the file, the remainder is silently appended. Use `Remove-Item` to delete the stale file, then `create_file` to write the new content in full. Avoid `Set-Content -NoNewline` when writing from a line array — it concatenates all elements without any separator, destroying all newlines.

---

### EF Core JSONB value comparers: count-only equality is a common silent data-loss pattern
Category: Process/Model

When auditing EF Core configurations for JSON/JSONB columns that store collections of objects (e.g., `IReadOnlyList<ValueObject>`), always verify the value comparer equality function compares **content**, not just **count**. The count-only pattern looks like:
```csharp
(a, b) => a != null && b != null && a.Count == b.Count
```
This causes EF Core change tracking to report "unchanged" when content is modified with no change in element count. The result is silent data loss on `SaveChangesAsync`. The correct pattern uses `SequenceEqual` (for flat value types) or element-by-element field comparison (for record/class types). When reviewing an EF Core entity configuration, scan all `.Metadata.SetValueComparer(...)` calls and verify the equality lambda does a structural comparison, not a shape comparison.

---

### Broad exception catch returning false success: audit for three compounding consequences simultaneously
Category: Process/Model

When a service method wraps multiple sequential DB writes in a single `try/catch (SomeDbException)`, audit for **three independent consequences** in one pass rather than only the most obvious one:

1. **Correctness:** Does the catch return a false-success value even when the write did not occur?
2. **Security/Audit:** Does the catch silently bypass a required security event (e.g., an immutable audit record write)?
3. **Token/resource re-use:** Is a session token or idempotency key marked consumed before the try, but the mark is part of the same rolled-back transaction? If so, the resource is reusable after a false success.

All three can be present simultaneously and compound each other. Flag all three under the same finding. Elevate to HIGH if any required security audit event can be bypassed.

**Detection pattern:** `catch (SomeDbException)` that returns the original success value instead of rethrowing — verify (a) the catch is narrowed to the expected exception subtype only, and (b) all side-effects (token consumption, audit writes) are either genuinely persisted or explicitly documented as not-persisted-on-exception.

---

### Compound risk analysis: medium + medium can equal HIGH when one exploits the other
Category: Process/Model

Two medium-severity findings can combine to create a HIGH-severity exploit path when one creates the precondition for the other. After listing all findings, do a second pass asking: "If finding X is triggered, does it make finding Y exploitable in a way it otherwise would not be?" If yes, flag them as a compound risk and cross-reference each from the other. Upgrade the combined severity to HIGH if the resulting exploit path is realistic (even if individually the findings are MEDIUM).

**Example pattern:** A defensive fallback returning `Guid.Empty` (MEDIUM) + a broad exception catch returning false success (HIGH) = ghost authenticated session for a non-existent user. Neither is apparent as HIGH when read in isolation.

---

### Auth token transport: always check whether short-lived tokens appear in redirect URLs during OAuth callback flows
Category: Process/Model

During security audits of OAuth flows that create server-side short-lived tokens (linking tokens, PKCE verifiers, state parameters), check the **transport mechanism** between the server-side callback and the client-facing page. Query parameters in redirect URLs are consistently logged by reverse proxies, CDNs, and access log pipelines. The fact that ASP.NET Core's OAuth middleware uses cookies for `state` and `code_verifier` is the definitive reference for the correct pattern in this framework.

**Key question:** "Does the token appear in any URL that the browser issues as a GET request?" If yes, flag as HIGH. The short token lifetime is no mitigation for a shared log pipeline where an attacker has read access.

**Correct pattern:** `HttpOnly; Secure; SameSite=Strict` cookie appended by the server-side callback handler; the confirmation page reads from the cookie, not the URL; the cookie is deleted server-side on first use.

---

### Open-redirect guard: verify with .NET runtime, not just logic analysis — `Uri.TryCreate` with `UriKind.RelativeOrAbsolute` silently passes `//host` URLs
Category: Process/Model

When reviewing an open-redirect guard that uses `Uri.TryCreate(url, UriKind.RelativeOrAbsolute, ...)`, always verify the actual runtime behavior for `//host` (protocol-relative) URLs. Logic analysis alone can miss this because `//attacker.com` is syntactically a relative URI in .NET's model (`IsAbsoluteUri = false`) but resolves as an external URL in every browser.

**Verification step**: Run `Uri.TryCreate("//attacker.com/x", UriKind.RelativeOrAbsolute, out var uri)` and inspect `uri.IsAbsoluteUri`. It returns `False` — which means any guard using `!uri.IsAbsoluteUri` passes the attacker URL.

**Correct fix pattern**: Use `UriKind.Relative` in `TryCreate` (rejects `//host`) AND add `url.StartsWith("/", Ordinal)` (rejects bare relative paths) AND add `!url.StartsWith("//", Ordinal)` as belt-and-suspenders.

**Secondary finding**: For Blazor Server apps, `NavigationManager.NavigateTo` during SSR prerendering emits a real HTTP 302 redirect — browser History API same-origin protection is irrelevant. The vulnerability is server-side when SSR is involved.

---

### Open-redirect correctness: also verify `javascript:` and `data:` URIs are correctly rejected
Category: Process/Model

When verifying an open-redirect guard, also run `javascript:alert(1)` and `data:text/html,...` through it. In .NET, `Uri.TryCreate("javascript:alert(1)", ...)` returns `IsAbsoluteUri = True` (the `javascript:` scheme is parsed as a valid URI scheme), so these are correctly rejected by `!uri.IsAbsoluteUri` guards. Document this explicitly in the audit to confirm the guard handles these vectors even if the main bypass (protocol-relative `//host`) fails.

---

### Test infrastructure audit: [SetUpFixture] namespace scope is a common correctness gap
Category: Process/Model

When auditing shared test infrastructure (`[SetUpFixture]`, `[OneTimeSetUp]`, Testcontainers fixtures), always verify:
1. Is the `[SetUpFixture]` class in a **named namespace** or the **root namespace**? Named namespace = scoped to that namespace only. Root (no namespace) = assembly-wide.
2. Does the class comment correctly describe its actual scope?
3. Are all test classes that depend on the fixture in the same namespace (or a child namespace)?

The failure mode: a `[SetUpFixture]` in `MyProject.Tests.Contract` starts a PostgreSQL container only for tests in that namespace. Tests added later in `MyProject.Tests.Unit` that call `PostgresContainerFixture.ConnectionString` will throw `InvalidOperationException` at runtime with a confusing message about "not started." This is a medium-severity correctness gap, not a current bug, but worth documenting for future-proofing.

---

### Opt-in inline authorization guard: flag as High when guard is copy-pasted across sibling write methods
Category: Process/Model

When a service class has 3+ write methods each containing an identical inline guard block (ownership check, IDOR check, etc.) with no shared helper, this consistently produces findings from FOUR independent auditors: Maintainability (DRY), Extensibility (no enforcement of guard on future methods), Ripple Effect (4th write path without guard), and Structural Patterns (new catalog entry: "Repeated Inline Authorization Guard"). Synthesize these as a single High finding rather than four separate Medium findings — the convergence signals a structural enforcement gap, not just a style issue. The actionable recommendation is always: extract `private void VerifyAccess(...)` and call it from all write methods so the compiler enforces guard presence on future additions.

**Companion check:** When auditing an opt-in guard pattern, immediately ask "are there N+1 write methods?" (Ripple Effect angle). The unguarded sibling is almost always present and is a consistent cross-auditor finding.

---

### Empty-array test assertions: distinguish shape verification from content verification
Category: Process/Model

When a test is named `List_ReturnsX_WhenEmpty` or has a comment claiming "DB is empty," check whether the assertions actually verify emptiness vs. just verify shape (e.g., `ValueKind == Array`). A test that only asserts `JsonValueKind.Array` passes whether the array has 0 or 100 items. This is a coverage gap for the "empty state" behavior. The correct approach depends on whether the empty-state path is actually exercised:

- If the DB is genuinely isolated (truncated), add `items.Should().BeEmpty()` or `items.Length.Should().Be(0)`
- If the DB is shared (not truncated), the test CANNOT verify emptiness — rename it to reflect what it actually tests (shape only) and add a separate test for empty-state using a filter that is guaranteed to return zero results
- Never leave a misleading comment claiming "no tasks exist" in a shared-container test

Flag this as Medium when found: the test is not incorrect but fails to cover the claimed behavior.

---


### Audit write target: iterate applied operations, not caller-supplied inputs
Category: Process/Model

When auditing code that writes audit records inside a loop (e.g., one record per decision in an `ApplyAsync`), verify whether the audit loop iterates the **operations that were actually applied** or the **caller-supplied input list**. A common pattern:

```csharp
// Primary action loop — iterates DB records, skips unmatched entries
foreach (var record in dbRecords)
{
    if (!decisionMap.TryGetValue(record.ItemId, out var decision))
        continue;  // race-condition no-op; nothing applied to this record
    // ... apply decision to record
}

// Audit loop — iterates ALL caller decisions, even those that weren't applied
foreach (var decision in decisions)  // ← BUG: should iterate only applied decisions
{
    await auditService.WriteAsync(new AuditRecord { ... Outcome = decision.Outcome });
}
```

If an entry exists in `decisions` but no matching `dbRecord` exists (e.g., the record was deleted between `PrepareAsync` and `ApplyAsync`), the audit loop writes a record claiming the decision was applied — but the primary loop skipped it as a no-op. The audit trail contains a **ghost record** for an action that never occurred.

**The correctness question:** "Does the audit loop write records only for operations that were actually executed?" If the audit loop has a different iteration source than the primary action loop, the answer is often no.

**Recommended pattern:** Accumulate applied operations in a list during the primary loop, then iterate that list in the audit loop:

```csharp
var appliedDecisions = new List<(Guid ItemId, EditDecision Decision)>();
foreach (var record in dbRecords)
{
    if (!decisionMap.TryGetValue(record.ItemId, out var decision)) continue;
    // ... apply
    appliedDecisions.Add((record.ItemId, decision));
}
// Audit loop only covers what was applied
foreach (var (itemId, dec) in appliedDecisions) { /* write record */ }
```

---

### Test strategy named tests vs. committed tests: always diff the two AND confirm the test is absent before flagging a gap
Category: Process/Model

When auditing a slice delivered with a test strategy document, the strategy file lists planned test method names. Always diff the planned names against what was actually committed in the test file. It is common for one planned test to be absent — especially "evaluator path" tests that were planned as companions to projector tests but were not written when the projector test already exercised the behavior transitively.

**CRITICAL**: Before reporting a test as missing in the requirements audit, actually open the test file and search for the behavior — not just the planned method name. Tests are frequently delivered under a different label but cover exactly the required behavior. Always search by behavior, not by the exact planned name.

---

### Overly broad DbUpdateException catch: returns false success when only unique-constraint should be swallowed
Category: Process/Model

When auditing a service that catches `DbUpdateException` to handle a "concurrent duplicate" scenario, always verify that the catch is **narrowed to unique-constraint violations only** (e.g., PostgreSQL SqlState `23505`). A bare `catch (DbUpdateException)` swallows all database errors — FK violations, connection timeouts, serialization failures — and returns the same "success" response intended only for the already-exists case. This produces three compounding correctness failures:

1. The operation is reported as succeeded when it did not complete.
2. The session / token / record that should have been marked consumed is NOT marked consumed (the EF transaction was rolled back, including the UsedAt / consumed flag mutation).
3. The caller issues cookies, sessions, or confirmations for state that doesn't exist in the DB.

**The correctness question:** "If the `SaveChangesAsync` inside this catch-block throws for a reason OTHER than a unique constraint — would returning success be correct?" If no, the catch must be narrowed.

**The concurrent-confirm corollary:** For a genuine concurrent-confirm race (two requests with the same token), the behavior of a broad catch is actually correct IF the first successful commit already persisted the consumed flag. The second request's transaction rolls back but the first commit's value persists. The bug only surfaces for non-constraint errors. Distinguish the two scenarios carefully before rating severity.

**Recommended pattern:** Narrow with an exception filter, mirroring the pattern already used in the same codebase for account creation:

```csharp
catch (DbUpdateException ex) when (IsUniqueConstraintViolation(ex))
{
    // Concurrent duplicate — the record is already in place. Treat as success.
    return Result.Success(...);
}
// All other DbUpdateException variants propagate as 500.
```

---

### Validation asymmetry between create and update paths is a common OWASP bypass pattern
Category: Process/Model

When reviewing any service that exposes both a `CreateAsync` and an `UpdateAsync` method, always verify that **input validation guards are symmetric across both paths**. It is a common pattern to add payload-bounds checks (count limits, length limits, injection guards) to the create path and omit them from the edit path. The edit path accepts the same model types and writes to the same fields, so any missing guard on the edit path is a direct business logic bypass (OWASP A04:2021). Check: every `ArgumentException` guard in `CreateAsync` should have a counterpart in `UpdateAsync` for the same parameter.

---

### Never-throws contracts and NRT: severity is lower when nullable reference types are enabled
Category: Process/Model

When auditing a service that documents "never throws" but lacks a null-guard on its context/input parameter, check whether `<Nullable>enable</Nullable>` is set in the project file. With NRT enabled, callers passing null receive CS8604 at compile time, making the runtime NRE a non-call-site scenario in practice. Downgrade severity from High to Low when NRT is enabled and the parameter is typed as non-nullable. Still worth noting (consistent with peer services that do add an explicit guard), but not a blocking finding.

---

### Session retrospective as a requirements audit resource
Category: Process/Model

When auditing a feature that was delivered with a retrospective or session notes document, always check for that document in the feature's delivery folder. Retrospectives explicitly document skipped steps, process violations, and known gaps — they are a richer source of audit signals than git blame alone. A retrospective may surface findings such as: mutation testing not run, a process gate violation, or a traceability document not post-verified. Confirm all reported gaps before opening any test file.

---

### BCrypt paired API enforcement: standard vs Enhanced are silently incompatible
Category: Process/Model

When reviewing BCrypt.Net-Next usage, always verify the hash/verify calls are using the same API family as a matched pair:
- `BCrypt.HashPassword` / `BCrypt.Verify` — standard API
- `BCrypt.EnhancedHashPassword` / `BCrypt.EnhancedVerify` — enhanced API (stronger HMAC pre-processing)

Mixing them produces a silent false-negative: `EnhancedVerify` on a standard hash always returns `false` without throwing. This is a non-obvious security bug because the auth flow behaves as if every password is wrong — tests that rely on a seeded hash from a different method will pass for wrong reasons. Check both the hash creation site (signup / migration) and the verification site (login) for consistency.

---

### Cookie claims must use canonical/normalized values, not raw service-layer inputs
Category: Process/Model

When reviewing auth endpoints that call a service with normalizing behavior (e.g., `NormalizeEmail = trim + ToLowerInvariant`), always check what value is used to populate the session cookie claims vs. what the service actually stores. The endpoint typically trims the raw form input before passing it to the service, but the service normalizes further (e.g., lowercases). If the endpoint issues the cookie with the pre-normalization value, the `ClaimTypes.Email` claim in the cookie will not match the canonical stored email — a latent bug that causes silent failures in any future code that reads the claim for a DB lookup.

**Check pattern**: After a successful service call in a sign-in handler, trace the variable used in `SignInAsync` / `ClaimsPrincipal` construction back to its source. If it came from user input and the service normalizes that input further before storage, flag a mismatch. The fix is to apply the same normalization at the endpoint level before cookie creation.

---

### Authorization `@attribute [Authorize]` is authentication-only; permission checks are a separate gate
Category: Process/Model

When reviewing a Blazor component that has `@attribute [Authorize]`, verify whether the spec requires a more granular permission check (e.g., "Board owner or permissions-manage holder"). `[Authorize]` only guarantees the user is authenticated — it does not enforce any role or permission. In incremental permissions builds, this is often intentional (the evaluation engine isn't wired up yet). Always check the input packet's out-of-scope list before flagging as a gap; if the authorization evaluation engine is listed as out-of-scope, classify as Medium deferred-by-design rather than a defect.

---

### Signup race condition: read-then-write duplicate check needs conflict handling
Category: Process/Model

In sign-up flows, always check whether duplicate detection uses a read-then-write pattern without conflict handling. The pattern `AnyAsync(email)` → `SaveChangesAsync()` has a race condition: two concurrent requests can both pass the check and the second `SaveChangesAsync` will throw a `DbUpdateException` (PostgreSQL `23505` — unique constraint violation) instead of returning a graceful failure. This is true even when the service has a unique index on the column.

**What to look for**: `AnyAsync` or `FirstOrDefault` check → `Add()` → `SaveChangesAsync()` without a `try/catch` on `DbUpdateException`. Flag as Medium unless the endpoint is not callable concurrently (e.g., behind a hard rate limit or the account creation window is gated by an external factor). The fix is a targeted `catch (DbUpdateException ex) when (IsUniqueConstraintViolation(ex))` → return the appropriate failure result.

---

### Blazor Interactive Server: test environments may omit OAuth providers from DI
Category: Process/Model

When reviewing E2E tests for OAuth flows in a Blazor Interactive Server app, check whether the OAuth providers are actually registered in the test host. In apps that conditionally register providers only when credentials are configured (e.g., `!string.IsNullOrWhiteSpace(clientId) && !string.IsNullOrWhiteSpace(clientSecret)`), test environments without real credentials skip provider registration entirely. Tests that use simulation endpoints to bypass the real OAuth flow are correct design — mark the OAuth integration coverage as "simulation only" in the audit and flag it for the correctness auditor.

---
### Auth feature delivery: three mandatory symmetric-path checks
**Date:** 2026-05-29
**Category:** Process/Model

When a feature delivers a login or sign-in mechanism, three symmetric-path checks are mandatory before the Ripple Effect audit can pass:

1. **Login → Logout**: A login endpoint without a matching logout endpoint is always High severity and blocks merge. Users cannot end their session, all downstream session-management features (re-authentication, account switching, force-logout) are impossible, and session state from bugs introduced in this very feature persists indefinitely. Check `SignOutAsync` call sites before closing the audit.

2. **Test harness sign-in → claim structure alignment**: Any test-only sign-in simulation endpoint must issue claims in the exact same structure (claim types, value types) as the real auth implementation. A mismatch is a silent time-bomb: all existing tests pass (they don't read identity claims), but every future feature that reads the identity will have wrong values in all test sessions. Check that `ClaimTypes.NameIdentifier` value type (string literal vs. Guid), `ClaimTypes.Email` presence, and normalization match the production auth path.

3. **Real auth normalization → cookie claim normalization**: When the service normalizes an input (e.g., `email.ToLowerInvariant()`) before storage but the endpoint issues the cookie with the pre-normalization value, the cookie claim diverges from the canonical DB value. This is a latent access-control bypass for any future code that reads the claim for a DB lookup. Check what variable is passed to `SignInAsync` vs. what the service stores.

All three should be Ripple Effect High findings that block merge. None are detectable by correctness or unit test auditors alone.

---

### Base config credential check: verify environment-specific overrides actually cover the key
**Date:** 2026-05-29
**Category:** Process/Model

When a hardcoded credential is found in a base configuration file (e.g., `appsettings.json`), do not accept "there is an environment-specific config file" as mitigation without verifying the override. ASP.NET Core config layering means the base file is always loaded first; the environment-specific file only wins if it explicitly overrides the same key. Audit steps:

1. Read the base config file and identify all credential keys
2. Read every environment-specific config file that runs in production
3. For each credential key, verify it appears and is overridden in the production-environment file

A production config file that overrides Kestrel settings but not database connection strings is not a mitigation. The missing override makes the base-file credential the active production value. Always confirm, never assume.

---
## Parallel auditor count in SKILL.md diverges silently when a new auditor is added
**Date:** 2026-05-28
**Category:** Process/Model
**Observation:** The SKILL.md Agent Roles table listed 7 parallel auditors; the deployed agents list contained an 8th (`REVIEW-StructuralPatternsAuditor`). Because the SKILL.md was the reference an agent read when planning the parallel phase, the 8th auditor was silently skipped — no error, no warning, just a missing dimension. The agent only discovered the gap when the user pointed it out. The same SKILL.md also had three stale count references (Overview, Coordinator row description, FinalSynthesizer row, LL rules) that all disagreed with each other and with reality.
**Guidance:** Before kicking off the parallel phase, always cross-check the Agent Roles table in SKILL.md against the `<agents>` list in the active configuration. If they disagree, fix the SKILL.md first. Any time a new REVIEW-* agent is added to the agents list, the following five locations in SKILL.md must be updated atomically: (1) Overview "N-agent system" count, (2) Overview "M specialist auditors" count, (3) Coordinator row "Spawns the M parallel auditors", (4) FinalSynthesizer row "Reads all N audit reports", (5) LL directory tree, (6) LL rules "reads all M per-auditor LL files".

---

### Pure-logic evaluator correctness: always verify the happy-path of the primary grant mechanism
**Date:** 2026-05-28
**Category:** Process/Model

When reviewing a precedence-chain evaluator (permissions, policy, feature flags), test authors naturally write for conflict resolution, edge cases, and failure modes. This means the happy path for the primary grant mechanism — the normal case where a user gets access because a policy grants it — is often completely absent from the test suite. The implementation can be entirely correct while the core "user can access thing" path has no coverage.

**Detection step**: After reading the test file, ask: "Is there at least one test that returns Allow (or the positive outcome) from the primary configuration mechanism (role template, policy, grant)?" If the answer is no, that is a HIGH gap — the most operationally important branch is unprotected.

**Related**: Also verify that all trace labels produced by the evaluator are exercised in at least one test. Unlabeled trace branches (e.g., `"role template deny"`) are a signal of missing coverage.

---

### Precedence-order guarantees require ordering tests, not just isolation tests
**Date:** 2026-05-28
**Category:** Process/Model

When an evaluator documents a precedence ordering guarantee (e.g., "Step 1 always beats Step 2"), tests typically verify each step in isolation: "Step 1 fires when its condition is met" and "Step 2 fires when its condition is met." These tests pass whether or not the steps are evaluated in the correct order. The ordering guarantee itself — "Step 1 beats Step 2 even when Step 2's condition is also met" — requires a dedicated test that activates both conditions simultaneously and asserts which one wins.

**Detection step**: For any documented ordering property (e.g., "owner guardrail applies before direct overrides"), search the test suite for a test that sets up *both* conditions at once and asserts the higher-priority step wins. If no such test exists, flag it as HIGH — a refactor that swaps the steps would leave all existing tests green.

---

### Binary access-decision enums must have Deny (or the restrictive value) as member 0
**Date:** 2026-05-28
**Category:** Process/Model

Any enum used to represent a binary access or authorization decision (Allow/Deny, Permit/Reject, Grant/Block) should have the **restrictive value as member 0** (the type-system default). In C#, an uninitialized enum field defaults to `0`. If `Allow = 0`, then any hand-written stub, test double, deserialized result with a missing field, or future ORM-materialized object silently grants access. This is exploitable at every layer — mock setup, cache hit miss, JSON deserialization — and none of the failures are compile-time.

**Detection step:** When reviewing any `enum` whose values represent an authorization outcome, check which member is at position 0. If it is the permissive value, flag as High.

**Fix:** Reorder so `Deny = 0` (or equivalent restrictive value). This is a one-line change with no behavioral impact on correctly-initialized code, but eliminates a whole class of silent grant-by-default failures.

---

### When multiple auditors flag the same finding from different dimensions, it is always real
**Date:** 2026-05-28
**Category:** Process/Model

In multi-auditor reviews, when two or more auditors independently flag the same code element from different analytical angles (e.g., Correctness flags it as a contract violation, Testability flags it as an untestable path, Security flags it as an exploitable surface), the finding is never a false positive — it is a genuinely multi-dimensional concern. During synthesis, these should be **de-duplicated but severity-upgraded**: if any one auditor rated it High and others rated it Medium, synthesize at High and cite all flagging auditors.

When the same code element is flagged by Code Correctness, Testability, Security, and Unit Test Coverage from four different angles, each analysis is typically valid and complementary — they surface different risk dimensions of the same root cause.

---

Category: Process/Model

When a change set is a follow-on to a prior code review (e.g., Phase 4 tests following a Phase 3 review), the Requirements Auditor should explicitly cross-check every bug-fix finding from the prior review against the new test suite. If a prior finding is listed as fixed in the code, there should be a unit test for the previously-broken condition. The absence of such a test is a Critical gap — the fix can silently regress.

**Detection steps:**
1. Read the prior code review report and extract all bug-fix findings (any "was broken, now fixed" entry).
2. For each fix, identify the condition that was broken.
3. Search the new test suite for a test that seeds the previously-broken condition and asserts it is now correct.
4. If no such test exists, flag it as Critical in the gap section.

This check takes ~2 minutes and catches the most regression-prone coverage holes in any test-writing session.

---

### Requirements audit descriptions of data-testid values may not match actual code — always read the component
Category: Process/Model

When a requirements audit is derived from the change set (no work item), the auditor may describe `data-testid` values by reading the component and transcribing what they expect the value to be. In practice, they may transcribe the *button text* or *intent* rather than the actual attribute value. For example, a button labeled "Reset to Default" may have `data-testid="reset-action-btn"` in the code, but the requirements audit transcribes it as `reset-to-default-btn`.

**Rule**: Always read the component file directly and extract the actual attribute string. Do not trust the requirements audit description of `data-testid` values — verify each one independently. Both names may be plausible; only one is the truth.

---

### Structural refactoring commits: flag toggle evaluation timing shift as a targeted correctness check
Category: Process/Model

When a private `BuildX()` method is extracted into a factory `Build()` method, pay attention to **when** toggle checks inside the old method were evaluated. If the old method was called once at construction time (e.g., in a constructor body), the toggle was evaluated once. If the factory `Build()` is called multiple times per request (e.g., once per variant), the toggle is evaluated N times. This is almost always equivalent, but it is worth noting for the correctness auditor if toggle values could theoretically change between calls within a single request. Frame it as a "verify immutability" check rather than a "defect" finding — 9 times out of 10 it is a non-issue, but it is easy to overlook and cheap to verify.

---

### Scenario ID mismatch between spec files and test descriptions: always cross-check ID labels against content
Category: Process/Model

When auditing a feature where scenario IDs appear in both a spec file (e.g., `02-scenarios.md`) and E2E test `[Description]` attributes, always cross-check the ID label against the scenario content — do not assume they match. A common failure mode: the test file was written with scenario IDs offset by 1 or 2 from the spec file (e.g., tests 04–06 describe different behaviors than scenarios 04–06). This breaks traceability for future auditors even when behavioral coverage is otherwise complete.

**Detection:** For each scenario labeled SCEN-XX-NN in a test file, look up SCEN-XX-NN in the spec and compare the "Given/When/Then" or description text. If they describe materially different behaviors, flag as a Medium traceability gap.

**Consequence to check:** Once you find a numbering offset, verify that no scenario from the spec is entirely missing from the test file. The offset often means one scenario was dropped entirely (or a new scenario was inserted mid-range pushing others down).

---

### `DbUpdateException` catch-all in multi-step write methods: verify the optimistic-write assumption
Category: Process/Model

When auditing a service method that sets a "consumed" flag on an entity (e.g., `session.UsedAt = now`) before calling `SaveChangesAsync`, then catches `DbUpdateException` to handle duplicate-identity failures, verify whether the consumed-flag mutation is durable after the exception path. EF Core batches all tracked changes into a single transaction — if `SaveChangesAsync` throws, the entire transaction is rolled back including the `UsedAt` write. The entity is then still in the "unconsumed" state in the database. If the catch block returns success (treating constraint violation as idempotent), the session remains reusable by a second confirm request.

**The correctness question:** "If the `DbUpdateException` fires, is the consumed-flag mutation guaranteed to have persisted?" If the flag and the constrained record are in the same `SaveChangesAsync` call, the answer is no.

**Recommended pattern:** Either use a two-phase write (consume session first in one `SaveChangesAsync`, then create the identity in a second), or accept the race and document it as a known limitation. Never silently return success from a catch that may leave the consumed flag unpersisted.

---

### Method-extraction refactors: "field removed, parameter retained" is a valid pattern — not an orphan
Category: Process/Model

When a private method is extracted out of a class into a factory, some constructor parameters of the original class may appear to lose their field assignment in the diff (the `private readonly _x = x;` line is removed). Do NOT flag this as an orphaned parameter or a bug. It means the parameter had **two usages** before the extraction:

1. Stored as a field to feed the now-removed private method
2. Used directly inline in the constructor body to construct other objects (no field needed)

After extraction, usage (1) disappears (the factory gets the service via its own DI injection), but usage (2) remains. The parameter must stay; only the field assignment goes. Check the full constructor body for inline usages before writing a "dead parameter" finding. Typical examples: any service that is used both by the extracted method AND by other inline object construction within the same constructor — the field assignment disappears while the parameter remains because the latter usage survives.

---

### Filter-removal changes: treat the removed guard as a formerly-implicit invariant and verify it holds downstream
Category: Process/Model

When a change removes a `.Where(x => x.SomeCount > 0)` or similar guard filter, always ask:
1. **Was the guard also protecting a downstream `.First()` or `.Single()` call?** Removing the filter can
   expose a `InvalidOperationException` / `Sequence contains no elements` throw at a call site that was
   never reachable before. Audit the full call chain from the removed filter to any sequence-access
   without null handling.
2. **Is the new inclusive behavior tested?** The scenario that the filter was excluding (e.g., zero items matching the old guard condition) is by definition untested with the old code. A dedicated test that seeds
   the previously-excluded case and asserts it now flows through correctly is required — it is the only
   test that actually exercises the behavioral change.

Common failure mode: a test that mocks the downstream method entirely confirms orchestration but does not exercise whether the downstream method handles the newly-admitted inputs. Flag this gap explicitly.

---

### Requirements audit without a work item: derive requirements by feature area, then identify instrumented-but-untested gaps
Category: Process/Model

When no work item or PR description exists, structure the audit around **feature areas** inferred from the
diff rather than a flat list of file changes. Group changes by intent: (1) foundational abstractions, (2)
refactors that use them, (3) new entry points that depend on the refactors, (4) downstream behavior changes.
This ordering naturally surfaces C-level gaps (new entry points with no call site) and M-level gaps
(calculator methods with no tests) that a file-by-file scan would miss.

**Key gaps to check in structural/mathematical change sets:**
- New calculator dispatch methods → check whether the corresponding `*Tests.cs` was updated
- New factory methods on an interface → grep all `*.cs` for call sites; flag missing wiring as Critical
- Deleted guard clauses (`.Where(...)` filters) → verify a new test documents the now-inclusive behavior

---

When performing a requirements audit on a change set that has no associated work item, the most productive structure is:

1. Group requirements by **feature area** (e.g., "Testable Startup", "data-testid Instrumentation", "Bug Fix", "New Test Suite") rather than by file. This produces a requirements document that maps naturally to what reviewers need to reason about.
2. For UI component instrumentation commits (adding `data-testid` attributes), the most valuable gap check is: **for each new `data-testid`, is there at least one test that uses it?** A `data-testid` that exists on the component but is never referenced in any test is a coverage gap, not a correctness gap — but it is still worth flagging at Critical if the attribute is on a primary action button.
3. For ViewModel bug fixes, check that the new filter clause is covered by at least one test that seeds a task matching the newly-excluded condition and asserts it is absent from the filtered output.

---

### Substring-in-keyword-array: FirstOrDefault vs Where/Count determines whether it's a defect
Category: Process/Model

When a keyword array has A ⊂ B (e.g., "fix" is a substring of "hotfix" and both are in the array), whether this is a defect depends on **how the array is queried**:

- `FirstOrDefault(k => text.Contains(k))` — returns at most one result. A substring relationship causes the shorter keyword to be returned instead of the longer one (because it appears first), but no double-counting occurs. **Not a defect for this usage pattern.**
- `Where(k => text.Contains(k)).ToList()` + `Count` — both A and B match a text containing B, producing a count of 2 from one textual concept. **This IS a defect for threshold-based scoring.**

---

### Structural patterns auditor may re-classify an Extensibility/Maintainability Low as Medium
**Date:** 2026-05-28
**Category:** Process/Model

When a Structural Patterns auditor reviews code that was also audited by Extensibility or Maintainability, it may assign a **higher severity** to the same structural concern. Specifically: an Extensibility finding classified as Low ("consider extracting if it grows") may become Medium from Structural Patterns when a named structural signal (e.g., numbered step comments, SP-001) is present today and the growth trigger (stub methods being implemented in a future slice) is scheduled and imminent.

**Synthesis rule**: When Structural Patterns and another auditor flag the same code location, use the **higher of the two severities** and cross-reference both auditor IDs in the consolidated finding. The structural auditor's assessment is typically more reliable for forward-looking structural concerns because it applies pattern-specific criteria rather than general code-quality judgment.

---

### Early-exit precedence chain vs. stage-accumulation pattern (SP-001 vs SP-006) disambiguation
**Date:** 2026-05-28
**Category:** Process/Model

A common false-positive risk during structural patterns review is conflating an **early-exit precedence chain** (N if/return blocks in sequence — first match wins) with a **stage-accumulation pattern** (SP-006: all N steps run, results collected into a result record with one field per step).

The surface signal for both patterns is "N numbered sequential blocks in one method body." The distinguishing questions are:
1. Does each block use `return` to short-circuit (early-exit chain), or does it accumulate results and fall through (stage-accumulation)?
2. Does the result type have one field per step, or a single outcome + metadata?
3. Does adding a step require adding a field to the result type (stage-accumulation) or just a new conditional block (early-exit chain)?

**SP-001 (Numbered Step Comments)** fires on early-exit chains and signals a method-extraction opportunity. **SP-006 (Closed Stage List)** fires on stage-accumulation and signals open/closed principle concerns. **Do not co-report SP-001 + SP-006 for an early-exit chain** — the result type does not grow per step, and there is no closed-set extensibility risk in the SP-006 sense.

Detection shortcut: find all (A, B) pairs in the array where `B.Contains(A)`. Then check which query pattern is used. Only flag as a defect if the counting pattern is used. Do not flag for `FirstOrDefault` usage.

---

### Keyword/scoring array audits: check for duplicates AND substring relationships
Category: Process/Model

When auditing a classification or scoring engine that uses a static string array for keyword matching against free text (e.g., an importance scorer, a crisis keyword detector, a category classifier), always check for two defect classes:

1. **Literal duplicates** — the same keyword string appears at two different indices. If the scorer counts `hits.Count` over the full array, a single text match produces a count of 2 instead of 1. Causes inflated scores for any text containing that keyword.

2. **Substring relationships** — keyword A is a proper substring of keyword B (both in the array). Any text containing B will also match A, producing a count of 2 from a single textual concept. Common pairs: `"test"` / `"testing"`, `"automate"` / `"automation"`, `"doc"` / `"documentation"`.

Both defects are invisible in happy-path tests (single keyword, no overlap) and only emerge when reviewing the array contents directly. Detection steps:
- Scan the array for literal duplicates (sort and compare adjacent, or use a Set)
- For each pair (A, B), test `B.Contains(A, StringComparison.Ordinal)` — if true, text containing B will double-count

Flag these as High severity when the scoring threshold is close to the overcounting delta (e.g., threshold=3, duplicate adds +1 → a 2-keyword task becomes incorrectly "important").

---

### Always invoke REVIEW-ParallelAuditCoordinator — never call specialist auditors directly
Category: Process/Model

When the orchestrator reaches the parallel phase of a code review, it must invoke `REVIEW-ParallelAuditCoordinator` as a single subagent call — **never** call each specialist auditor (`UnitTestCoverage`, `Maintainability`, `Performance`, `Security`, `Extensibility`, `RippleEffect`, `Testability`) individually and sequentially. The `runSubagent` tool blocks until the called agent finishes; looping through 7 sequential `runSubagent` calls produces a fully serial execution even though the agents are labeled "parallel." The `ParallelAuditCoordinator` exists precisely to solve this: it launches all 7 as concurrent subagents from within a single agent turn. Calling specialists directly one-by-one is always wrong at the orchestrator level.

---

### Gap amplification: always trace ViewModel when flagging a missing UI action
Category: Process/Model

When the Requirements Auditor flags a missing UI action (e.g., "no Reset button for a given status"), the Correctness Auditor must trace through the ViewModel command handler to verify it supports the intended transition. A button wired to a command that maps to a status not in the switch statement will silently no-op — the ViewModel logs a warning and returns null, the async command swallows the exception, and the user sees no feedback. Both the UI fix and the ViewModel fix are required together. Flag as a co-dependent finding with the same severity as the UI gap.

---

### Category-filter bypass: check ALL views, not just the one cited in the requirements audit
Category: Process/Model

When a requirements audit flags one view bypassing `FilteredTasks` (e.g., MatrixBoardView), always check every other view in the same library for the same pattern — especially views with their own ViewModel-computed list properties (e.g., `WhatNowTasks`). The root cause (reading `Tasks` instead of `FilteredTasks`) is easily replicated across views written at different times. A single G-04 finding may mask a sibling issue in another view with the same root.

---

### "Scoped" in a class name does not mean Scoped registration lifetime
Category: Process/Model

When auditing a class named `Scoped*Factory` or `Scoped*Service` that is registered as Singleton, do NOT flag it as a captive dependency without first inspecting its constructor. The pattern where a class is named "Scoped" because it creates per-call scopes internally (via `IServiceScopeFactory`) — rather than being a per-scope instance itself — is common in ASP.NET Core. The key inspection rule:

- If the constructor captures only `IServiceScopeFactory` (a framework singleton): Singleton registration is correct and safe
- If the constructor captures any Scoped service (e.g., DbContext, a scoped user service): Singleton is a captive dependency bug

Do not write a captive dependency finding until you have confirmed the constructor captures a scoped service. "Scoped in name" is not evidence. Always read the constructor.

---

### Comment-code contradiction is a regression trap, not a cosmetic issue
Category: Process/Model

When a code comment (especially in a script's changelog or header block) says "we do NOT do X" and the code actually DOES do X, rate this as Medium severity — not Low or cosmetic. The risk is not the current behavior (which is correct), but the next maintainer who removes X "to align code with the comment." This pattern has caused real regressions. Flag it explicitly and recommend a one-line comment fix before merge.

---

### Dead code claims require full-file verification
Category: Process/Model

Before including any "dead code" or "unreferenced symbol" finding, verify zero usages across the **entire file** — not just the sections that changed in the PR. Use `Select-String -Path <file> -Pattern <symbol>` or the `search/usages` tool. A symbol removed from one code path may still be referenced by other methods in the same file. An unverified dead-code claim produces a concrete, actionable-looking "remove before merge" finding that is wrong and damages report credibility.


---

### Complete file replacement via replace_string_in_file: use terminal write for large overwrites
Category: Process/Model

When a review artifact (e.g., `requirements-audit.md`) from a prior review session needs to be **completely replaced** — not incrementally patched — do NOT attempt piecemeal `replace_string_in_file` calls to swap old content for new content. This approach corrupts the file (partial matches, orphaned sections, duplicate blocks) and requires multiple recovery attempts.

**Correct approach:** Read the file to confirm it is fully old content, then write the new content in one terminal `Set-Content` call. This is the only reliable way to atomically replace a multi-hundred-line file. Accept that this is a terminal write; it is the right tool for the job when the file editing tools are structurally inadequate for a full overwrite.


---

### Null/empty-sentinel coverage: verify the sentinel-triggering input is present in parametrized tests
Category: Process/Model

When reviewing a toggle-gated fix whose mechanism is replacing one sentinel value with another (e.g., `DefaultIfEmpty(safeDefault)` replacing `DefaultIfEmpty(badDefault)`), verify that at least one parametrized test case supplies the specific input that produces an empty or null collection — the only input that actually exercises the sentinel path. If the `[TestCase]` attributes enumerate only the typical non-empty inputs, the sentinel path is silently uncovered even when the method name says "when no items."

---

### Empirical test output supersedes code-tracing for Critical findings
Category: Process/Model

When the developer provides a same-day validation or characterization test run, scan its output (e.g., Differences.xlsx files, test logs) **before** writing any Critical finding into a report. Empirical evidence resolves ambiguities faster than code tracing and can demote a Critical to a Non-Issue before it is published. Requirements and Correctness auditors are prone to flagging a missing code change as Critical when the behavior is already delivered via an emergent side-effect of a different fix. Rule: if validation data is available, analyze it first; rate a finding Critical only when the data confirms the gap, or when no validation data is available.


---

### Toggle-ON test branch dead code: check ToggleBuilder state before trusting if/else test assertions
Category: Process/Model

When a test file uses an all-features-disabled toggle fixture (e.g., built with a builder pattern that disables every flag by default) and then branches assertions with `if (toggles.IsEnabled(SomeFeature)) { ... } else { ... }`, the `if` branch is permanently dead code. The assertions inside will never execute. This pattern appears when a developer updates existing tests for toggle-aware behavior but forgets that the toggle instance is hardcoded to all-disabled. Before writing Requirements or Correctness findings about toggle-ON test coverage, always verify whether the toggle instance used in the test fixture is all-disabled vs. explicitly enabled. If all-disabled, every toggle-ON assertion in the file is dead and should be flagged as a Medium coverage gap.


---

### Special-case value guard: verify non-standard enum values before calling downstream mappers
Category: Process/Model

When reviewing a toggle-gated fix that calls a mapper or converter inside a helper that receives a typed enum parameter, always trace which enum values can reach that helper from the outermost callers. Some enum values may represent "special" or "sentinel" cases (e.g., test harness modes, placeholder values, non-numeric identifiers) that the downstream mapper does not handle and will throw on. Any helper called before a branch that filters those values, but that itself invokes the mapper without guarding for the special cases, will throw at runtime when those values arrive. The fix is a guard placed before the mapper call: `if (value is SpecialCaseA or SpecialCaseB) return fallback;`. Flag this pattern whenever a new toggle-gated helper performs enum-to-type mapping on a parameter whose full value range is not filtered upstream.

The intended behavior in most cases is: hide from the user's agent picker, but still allow trusted caller invocation. That requires `user-invocable: false`, NOT `disable-model-invocation: true`.

Rule: any agent that is meant to be called programmatically by a parent Orchestrator or Coordinator must use `user-invocable: false`. Reserve `disable-model-invocation: true` only for agents that must never be called by any agent under any circumstances.

---

### Special-case enum values require a guard before any mapper that does not handle them
Category: Process/Model

When reviewing a toggle-gated fix that calls an enum-to-type mapper inside a helper, always trace which enum values can reach that helper from the outermost callers. A domain enum often includes "special" or sentinel values (e.g., test harness modes, placeholder values, non-numeric identifiers) that the downstream mapper does not handle and will throw on. Any helper called before a branch that filters those values — but that itself invokes the mapper without guarding for the special cases — will throw at runtime when those values arrive. The fix is a guard placed before the mapper call: `if (value is SpecialCaseA or SpecialCaseB) return fallback;`. Flag this pattern whenever a new toggle-gated helper performs enum-to-type mapping on a parameter whose full value range is not filtered upstream.

---

### Auto-start lessons learned after the final review report — do not prompt
Category: Process/Model

The `lessons-learned` SKILL.md previously said to "always output a prompt to the user." The `general-agent-behavior` instructions override this: after a named workflow delivers its terminal output, proceed with lessons learned automatically without asking permission. For the code-review pipeline specifically: once `final-review.md` is written and presented, start lessons learned immediately in the same turn rather than prompting the user to type a trigger phrase.

---

### Refactoring PRs: verify all new `new ClassName()` calls have a resolvable class definition
Category: Process/Model

When reviewing a refactoring PR that moves instantiation from expression-bodied properties into constructors, new class names can be introduced (e.g., a new flow action added opportunistically alongside the refactoring). Always search the full `Source/` tree for each newly introduced `new ClassName()` call that does not already exist in the pre-refactor code. A class that is declared in the interface and instantiated in the constructor but has no `.cs` implementation file will cause a compile error. The VS Code `get_errors` tool is unreliable for this in large C# solutions — use `Get-ChildItem -Recurse -Filter "*.cs" | Select-String "class ClassName"` or a full-tree text search instead. Flag any missing class definition as Critical severity.

---

### Stale code-review/ artifacts in cherry-picked commits must be deleted — noticing is not enough
Category: Process/Model

When a cherry-picked commit contains `code-review/` files (audit reports from a previous review session that were accidentally committed to the source branch), cherry-pick dumps them directly into the working tree. If left in place, every subsequent pipeline stage reads stale report content instead of producing fresh output. This causes cascading failures: requirements-audit.md is pre-populated with wrong data, code-correctness agents re-read that stale content, and all audit results are unreliable.

**Two failure points — fix both:**

1. **PrepareCommitReview workflow**: After all commits are cherry-picked, immediately check for and delete any `code-review/*.md` files (but NOT `code-review/session-config.json`). Do this as a final cleanup step before saving the config and reporting success. Command: `Remove-Item code-review\*.md -ErrorAction SilentlyContinue`

2. **Orchestrator scope summary**: When the changeset diff shows `code-review/` files, do NOT merely note this in the summary — **delete them immediately** before confirming readiness with the user. Writing "Note: these are artifacts from a previous session" in the summary and then doing nothing is worse than useless: the user reads "I know about this" and assumes it is handled. The Orchestrator must delete the files, then confirm the deletion in the summary.

Rule: at no point should `code-review/*.md` be present in the working tree when a new pipeline run begins. If they are detected at any stage, delete them before proceeding.

DO: Start the lessons learned session automatically after the final report is presented.
DON'T: Print "type 'lessons learned session'" and wait — the user must not have to ask for this step.

---

### Standing project reviews: check for code-ahead-of-docs discrepancies as a separate category
Category: Process/Model

In standing project reviews (no PR/diff), architecture documentation may describe a feature as "not yet implemented" (e.g., "no authentication enforced today") when the code has already implemented it. This is not a gap — it is a documentation drift discrepancy. Flag it in its own section (e.g., "Architecture Documentation Discrepancy") separate from the Gaps section, and label it as requiring a documentation update rather than a code change. Mixing documentation drift into the Gaps list inflates the gap count and misleads downstream auditors about what work is required.

---

### Standing project reviews: read architecture docs before source code, not after
Category: Process/Model

In a standing review (no diff), the order of operations matters: read architecture docs first, extract the behavioral contracts and acceptance criteria, then read source files and check each contract. Reading source first produces a bottom-up description of what the code does; reading docs first gives you the expected contracts to validate against. The top-down approach surfaces deviations (both under-implementation and over-implementation) more efficiently.

---

### Dead code verification on Windows: use `Get-ChildItem | Select-String` not `Select-String -Recurse`
Category: Process/Model

On Windows PowerShell, `Select-String -Recurse` does not accept a `-Recurse` parameter — it is not a valid flag. Use the pipeline pattern instead: `Get-ChildItem <path> -Recurse -Include "*.cs","*.razor" | Select-String -Pattern <symbol>`. This produces reliable cross-file symbol search results. The `Select-String -Path <file> -Pattern <symbol>` form works for single-file searches. Any auditor or synthesizer that needs to verify a dead-code claim on Windows should use the `Get-ChildItem | Select-String` pattern, not `Select-String -Recurse`.

---

### Environment lifecycle verification is required for conditional skip decisions that test mutable state
Category: Process/Model

When auditing a conditional skip (e.g., "skip this step if flag X is set"), always trace the **full lifecycle** of flag X — not just where it is set, but where it is cleared. Specifically:

1. Find every call site that sets flag X to a truthy value
2. Find every call site that resets flag X to null/false
3. Map those calls against the flow execution order: does reset happen **before** the guarded step on every path where it should not skip?

This is particularly easy to overlook when the flag is set inside a nested sub-flow and the guarded step is in an outer loop that reruns. A developer reading the conditional skip logic in isolation may not trace whether the flag is still set from the previous iteration's nested sub-flow. On the other hand, a framework-level reset at the start of the outer iteration may silently make the logic safe — but only if you verify it exists.

Rule: for any "is state X set?" check in a conditional gate, verify that X is cleared by a reliable mechanism before the gate is re-evaluated in any subsequent pass.



