# Lessons Learned: REVIEW-SecurityAuditor

> GLOBAL FILE. Abstract patterns only — no class names, file paths, or project-specific identifiers.

---

## When to Append

Only append if the session revealed something surprising, a false-positive pattern, or a finding worth noting for future security reviews. Skip if the review ran smoothly.

---

### Caller-controlled boolean flags as authorization bypasses
A method that accepts a boolean parameter controlling whether a permission check is applied (e.g., `skipOwnershipCheck: true`) is a trust boundary violation. The check must be internal to the service; callers must never control whether it fires. Any such parameter is High by default — it is an implicit "I trust the caller" flag with no enforcement.

---

### Test harnesses that wrap the full DI container: check for security-relevant services excluded from the test environment
When an integration test registers the full production DI graph, verify that all security-relevant services (auth middleware, ownership guards, permission evaluators) are present. A test that bypasses DI registration for a security service is silently testing a less-guarded variant of the application.

---

### Security-sensitive enums: deny-by-default ordering
For enums used in authorization decisions, the `0`/default value should represent the most restrictive state (deny, no-access, unknown). If `0` maps to "allowed" or "admin," a default-initialization bug silently grants access. Rate Medium when the default-grants-access condition exists.

---

### Privilege-flag POCOs: the caller who builds the object is the trust boundary
When a DTO or record carries a boolean privilege flag (e.g., `IsAdmin`, `CanEdit`), and the caller constructs the object, the caller controls the privilege. Any code path that constructs a privilege-carrying object from caller-supplied data without server-side verification is a High finding.

---

### `virtual` on a security-critical property: subclass override bypasses the guard
When a property that drives an authorization decision (e.g., `IsOwner`, `HasPermission`, `IsEnabled`) is `virtual` on a non-sealed class, a test or future subclass can override it to return a fixed value. Rate Medium — not a runtime exploit in most production contexts, but a seam that subverts the guard in test code and introduces a maintenance risk.

---

### "Never throws" contracts and null input: implicit trust assumption
When a service advertises that it never throws, and its callers skip null-input guards on the basis of that contract, any future code change that introduces a throw silently removes a safety net. Rate Medium when a "never throws" contract has no test asserting the null-input path.

---

### Unconstrained audit/trace string fields are a log injection risk
When a method accepts a string parameter that is written to an audit log or trace output without sanitization, an attacker who controls that string can inject log entries. Rate Medium when the parameter originates from external input. The fix is always output encoding or structured logging (use a typed parameter, not a format string).

---

### Pure in-memory calculation engines: shift security focus to the context-construction boundary
When a security-relevant computation is a pure function (no IO, no auth calls internal to the function), the security audit focus shifts entirely to the context construction boundary — the code that assembles the inputs to the function. A pure calculator cannot have an authorization bug; the bug is always in how its inputs are assembled or how its result is used.

---

### Authorization precedence asymmetry: explicit deny should always beat explicit allow
When an authorization evaluator can receive both a deny and an allow signal for the same resource, verify which one wins. In most correct systems, explicit deny takes precedence over explicit allow. An evaluator where "any allow wins" is incorrect if deny signals can also be produced by legitimate policy.

---

### `IReadOnlySet<T>` and `IReadOnlyList<T>` are view restrictions, not permission restrictions
Exposing a collection as `IReadOnlySet<T>` prevents callers from calling Add/Remove through the interface — but any code that downcasts to the concrete type can bypass the restriction. Do not treat a read-only collection interface as a security control. It is a design aid, not an enforcement boundary.

---

### Dead-code security enum values: they will be reached by future callers
When an enum used in security decisions has a value that no current code path ever produces (confirmed dead code), rate it Medium — not Low. A future migration, copy-paste, or default-value bug will produce that value. The security decision for that value must be defined and tested before the value is "alive."

---

### Auth service accepting caller-trusted timestamps: receipt time must be server-assigned
When an auth service accepts a timestamp from the caller (e.g., "authenticated at: <client-provided datetime>") rather than recording the server-side receipt time, the timestamp field is attacker-controlled. Rate High if the timestamp is used in any expiry, audit, or security decision.

---

### Shared assignment API without ownership verification: cross-user assignment is possible
When a service's "assign X to Y" method verifies that the caller owns X but does not verify that Y is a valid assignment target for the caller's context, a caller can assign their legitimately-owned X to any Y regardless of permissions. Rate Medium.

---

### Audit logging on explicit deny operations: absence is Medium (A09:2021)
When code explicitly evaluates a deny decision and produces a denial result, a log entry should exist on the deny path. A service that logs creates but is silent on denies has an incomplete audit trail — the denial events are exactly the ones most useful for intrusion detection.

---

### Pure calculation modules: rapid OWASP disqualification is correct, not a skip
When an audited module is a pure calculator (no IO, no auth, no external calls), confirming that all OWASP categories are not applicable is the correct output of the security audit. A clean security verdict on a pure module is not a failure to find issues — it is the correct finding.

---

### `GetType().Name` in exception messages is an information-leak risk
Exception messages that include type names expose internal architecture to external callers. Rate Low for internal APIs, Medium for public-facing APIs. The fix is a fixed message string with no runtime type information.

---

### Filter removal on internal LINQ pipelines: verify this is not also removing a data-exposure filter
When a `.Where()` filter is removed from a LINQ query, check whether the filter was restricting which records were returned to the caller. A performance-motivated filter removal that was also limiting data exposure is a security regression, not just a correctness question.

---

### `[Authorize]` attribute on permission-management pages guards authentication, not authorization
An `[Authorize]` attribute verifies the user is authenticated. It does not verify the user has permission to manage other users' permissions. Pages that gate administrative operations need both authentication AND authorization role checks. Rate High if the admin action is reachable by any authenticated user.

---

### IDOR asymmetry: read paths often have ownership filters; write paths often don't
It is more common to add an ownership filter to a read query ("only return records owned by the calling user") than to a write method. When auditing write paths, always verify the write method independently — do not assume read-path filtering extends to write-path enforcement.

---

### Placeholder actor identity in audit records: future-proof the actor field from the start
When an audit record stores "system" or a fixed string as the actor rather than the actual user identity, the audit trail cannot distinguish between legitimate automation and unauthorized access. Rate Medium when the actor field is available in the calling context but is not being passed through.

---

### Test readiness globals in production HTML are a Low severity finding, not dismissed
A production HTML file that defines a global JavaScript function whose only consumer is E2E test code (`window.setCircuitReady`, `window.waitForReady`) is unnecessary global exposure. Rate Low when the function only writes a DOM attribute. Rate Medium if it controls any UI access gate.

---

### Cookie middleware ReturnUrl validation and app-level login-page ReturnUrl validation are independent code paths
When cookie auth middleware correctly validates ReturnUrl internally (`IsLocalUrl`), that does not protect a login component that independently reads ReturnUrl from the query string via its own parameter binding. Audit both paths separately. An attacker can craft a direct URL that bypasses the middleware validation path.

---

### `CookieSecurePolicy.SameAsRequest` is insecure without `UseForwardedHeaders` behind an HTTP reverse proxy
Without forwarded-header configuration, Kestrel sees HTTP requests and issues auth cookies without the `Secure` attribute. Always check for either `CookieSecurePolicy.Always` or `UseForwardedHeaders` before the auth middleware when auditing cookie auth behind a proxy. Rate Medium for typical reverse-proxy deployments.

---

### IDOR guards: ownership key AND resource type discriminator must both be checked
When a storage table holds multiple resource types distinguished by a type discriminator, an ownership-only check (`resource.OwnerId == requestingUserId`) allows type-A requests to pass a guard designed for type-B. Rate Medium when a second code path can produce type-B records with a valid owner.

---

### Successful writes in permission-management services require success-path audit logging
Editing a permission template is the highest-consequence write in most permissions systems — a single edit changes effective permissions for every assignee. Verify that the update path logs on success, not just on failure. An absent success log creates a false impression the audit trail is complete. Rate Medium (A09:2021).

---

### SignalR auth token in URL query string is a High finding
When a `HubConnectionBuilder` URL contains an interpolated auth token, the token appears in server access logs unconditionally. Rate High for long-lived tokens (machine registration, API key); Medium for short-lived per-session tokens. The correct pattern is `AccessTokenProvider` on the builder, which sends the token as a header during the negotiate phase.

---

### LLM dispatch architecture: prompt injection is inherent when user-authored fields are included in prompts
When a system constructs LLM prompts from data fields authored by users (task titles, descriptions, comments), prompt injection is present by design. The standard mitigation is a fixed, non-overridable system preamble that scopes the agent. Rate Medium for internal tools with authenticated task creation; High if task creation is externally accessible; Critical if the agent has unrestricted shell or filesystem access.

---

### Scope-relative severity for absent authentication
Do not rate absent auth as Critical/High at face value when the application is demonstrably scoped to local single-user use. Apply a deployment-context matrix: localhost-only = Medium; LAN-accessible = High; internet-facing = Critical. Flag with the escalation condition explicitly.

---

### Binary database files in Git: check for credential or key material embedded in the binary
When a commit adds a binary database file (SQLite, Access, etc.) to source control, the file may contain seed data including passwords, API keys, or user credentials that will appear in git history permanently. Rate Medium by default; escalate to High if the database schema includes credential tables.
