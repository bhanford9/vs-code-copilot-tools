# Lessons Learned: REVIEW-SecurityAuditor

> # ⚠️ GLOBAL FILE — CODEBASE-SPECIFIC CONTENT IS STRICTLY FORBIDDEN
>
> **This file is committed to a public shared repository and read across all projects and codebases.**
>
> **BANNED — do NOT write any of the following:**
> - Class names, interface names, method names, type names, field names
> - File paths, namespace names, project names, solution names
> - Work item IDs, ticket numbers, branch names, version identifiers
> - Domain-specific abbreviations or industry jargon unique to one team or product
> - Any identifier specific to one repository, team, or system
>
> **Write ONLY:** abstract patterns, heuristics, and model-behavior observations that apply to any codebase.
>
> **Proper-noun test:** Remove all proper nouns from your proposed entry. If it still makes sense as general engineering advice, it belongs here. If understanding it requires knowing the project, move it to `LessonsLearned.md` (gitignored, local only).
>
> **MANDATORY SANITIZATION GATE — run before every append:**
> 1. List every capitalized identifier and domain abbreviation in the proposed text.
> 2. Classify each: standard framework/language type (safe) OR project-specific (banned).
> 3. Replace all project-specific items with generic placeholders before writing.
> 4. Re-read. If the entry still requires knowing the project to understand it, move it to `LessonsLearned.md`.
>
> ⚠️ **Most common violation: an abstract lesson body with a concrete project-specific example. Generalizing the headline is not enough — generalize or remove the example too.**

---

## Base `appsettings.json` Is Active In ALL Environments

ASP.NET Core config layers: `appsettings.json` (always loaded) → `appsettings.{Env}.json` (merged on top). A hardcoded credential in the base file is a security risk even when the environment-specific file is present — it is only safe if the environment-specific file explicitly overrides that key. Always confirm the override exists for every environment that runs in production.

## `[JsonIgnore]` on Credential Fields Is Necessary But Not Sufficient

`[JsonIgnore]` blocks default System.Text.Json serialization. It does nothing for: structured loggers that inspect object graphs, direct entity returns in controller actions, and diagnostic/debug endpoints. Verify at the API boundary that sensitive entities are never returned directly.

## `PGPASSWORD` in Process Environment Deserves Medium Severity

Passing credentials via process environment variables (`PGPASSWORD`) is standard practice for non-interactive `pg_dump`, but it exposes the credential in the OS process table for the lifetime of the process. Flag as Medium (not Low) in any production-facing service. Note the mitigation path: a temporary `pgpass` file with restricted permissions, removed after the subprocess exits.

## Caller-Controlled Boolean Flags Are an Authorization Bypass Risk

When an authorization service accepts pre-evaluated boolean flags (e.g., `hasSomePermission = true`) from the caller rather than evaluating permissions itself, there is no structural enforcement that the caller used the correct evaluation method. Any caller can forge the flags by construction. This is a High security finding when: (a) the flag controls access to a sensitive operation, (b) no production callers exist yet (making the risk latent but concrete), and (c) the interface documentation says "must be derived from X" without structural enforcement. Mitigation: private constructor + factory method that accepts the evaluator as a parameter and derives the flags internally.

## Test Harnesses That Wrap a Full DI Container May Include Network-Capable Commands

When a test harness builds the production DI container by calling the same registration extensions as the production host, every registered command is available — including commands that make outbound HTTP calls or write to global credential files. A test that accidentally invokes one of these commands (e.g., a registration command that overwrites a machine credential file) can have real side effects even in a "test only" context. When auditing test infrastructure, scan the full DI registration for any command or handler that makes outbound HTTP calls, writes to non-temporary global paths, or mutates shared state — then verify that the test harness cannot invoke them accidentally.

## Security-Sensitive Enum: Deny-by-Default Ordering

For any binary enum used in access-control decisions (Allow/Deny, Grant/Revoke), the restrictive value must be at ordinal 0. In C#, the zero value is the type-system default for uninitialized fields, unset struct members, and deserialized JSON missing the property. Flag any access-control enum where the permissive value is zero as a High finding. The fix is a one-line reorder with no logic change.

## Privilege-Flag POCOs: Caller Trust Is the Primary Attack Surface

When a pure-logic authorization engine is correct (fail-closed, right precedence, ordinal comparisons) but accepts all context flags via a plain POCO with no validation, the security risk shifts entirely to context-construction callers. Flag the absence of XML doc guidance (or a factory method) that enforces server-side derivation of privilege flags. This is High severity even when no caller exists yet — the gap must be closed before production callers are added.

## `virtual` on Security-Critical Properties Is a Test-Induced Design Risk

A `virtual` property on a context object that feeds an authorization engine allows subclasses to inject arbitrary values, bypassing `init`-only immutability. Even when the intent is test infrastructure, flag as Medium. Preferred fix: seal the class and use composition (mock interfaces) for test helpers instead of inheritance.

## "Never Throws" Contracts and Null Input

When an authorization/security interface documents "Never throws," validate the null-input path explicitly. A catch block that accesses properties on a potentially-null argument will throw a second exception inside the handler, violating the documented contract. Flag as Medium — the risk is callers that default to allowing access on unhandled exceptions.

## Unconstrained Audit/Trace String Fields Surfaced in API Responses

An unconstrained string field on a trace or audit result object that may be serialized to API responses is a latent sensitive-data exposure risk. Current code may be safe; future developers extending the engine may write internal policy data into the field. Flag if there is no doc comment or enum-based constraint defining the allowed vocabulary.

## Pure In-Memory Logic Engines: Shift Focus to Context Construction

When an engine performs no I/O, no database queries, and no shell operations, injection attack categories (SQL, command, path, template, expression) are not applicable. Note this as Info and concentrate review effort on: (1) how the input context/request object is populated upstream, and (2) result object design — default values, serialization surface, and unconstrained output fields.

**Severity guidance**: Low when the commands require explicit invocation with a real server URL (passive risk). Medium if the test harness registers these commands in a shared CI environment where real credentials could be discovered via environment variables.

## Authorization Precedence Asymmetry: Higher-Priority Steps May Have Weaker Scope Enforcement

When auditing a multi-step authorization engine (owner guardrail → direct override → role template grants → default deny), check that every step applies the same scope-filtering discipline. A common failure mode: the highest-priority step (e.g., an owner capability guardrail) matches only on permission string membership, while a lower-priority step (e.g., template grant resolution) correctly filters on both permission string AND resource scope. The higher-priority step then fires for permission strings that belong to a different scope than the resource being checked, producing an incorrect Allow. This is High severity because the higher-priority step cannot be corrected by downstream steps. When you find scope filtering in any step of the chain, audit every other step for the same check.

## `IReadOnlySet<T>` and `IReadOnlyList<T>` Are View Restrictions, Not Immutability Guarantees

When a security-critical in-memory catalog or allowlist is typed as a read-only interface (`IReadOnlySet<T>`, `IReadOnlyList<T>`) backed by a mutable concrete type (`HashSet<T>`, `List<T>`), it is mutable via downcast. The `static readonly` modifier on the field prevents reference replacement but not mutation of the referenced object. For a catalog used as a security gate (e.g., a permission string allowlist), flag as Medium and recommend switching to a structurally immutable type (e.g., `ImmutableHashSet<T>`). This eliminates the downcast attack surface and makes the immutability intent enforceable by the type system.

---

## Dead-Code Security Enum Values Create Operational Security Traps

When a security configuration enum contains a value whose documented behavior (e.g., "restrict to creator," "require approval") is unimplemented and instead behaves identically to the deny-all default, flag as Medium. The risk is not direct exploitation — the unimplemented value still blocks. The risk is operator behavior: an administrator who configures the value expecting the documented restriction, observes that all users are blocked, and escalates to a more permissive mode as a workaround. The gap between documented intent and actual behavior induces misconfiguration toward broader access. Recommended fix: update the XML doc to explicitly say "Reserved — not yet implemented. Behaves identically to [deny-all value]. Do not use in production." If possible, return a distinct denial reason so the operator can distinguish the not-implemented state from genuine misconfiguration.

---

## EF Core `SaveChangesAsync` Has Two Overloads — Guard Both

EF Core's `DbContext` has `SaveChangesAsync(CancellationToken)` and `SaveChangesAsync(bool acceptAllChangesOnSuccess, CancellationToken)`. Overriding only the single-parameter overload leaves a bypass path: any caller that invokes the two-parameter overload directly hits the base implementation without the guard. For security-critical overrides (audit immutability enforcement, row-level tenant isolation checks, soft-delete guards), both overloads must be intercepted. Flag as High when the override protects a compliance-grade invariant (e.g., an append-only audit trail). The fix is a one-line additional override.

---

## Auth Service Accepting Caller-Trusted Timestamps Is an Audit Integrity Risk

When an audit/trace write service accepts a fully caller-constructed record including a `Timestamp` field, and does not validate or override that timestamp, the audit trail can be tampered with by any internal caller: past-dating records to predate compliance windows, or future-dating records to sort them out of forensic scan ranges. Flag as Medium when the audit service is compliance-grade. Recommendation: the audit write service should override the timestamp with its own `TimeProvider.GetUtcNow()` rather than trusting the caller's value.

---

## Shared Assignment API Without Ownership Verification Enables Cross-Resource Injection

When a shared-assignment method (e.g., `AssignResource(resourceId, scopeId)`) does not verify that `resourceId` belongs to `scopeId`, an actor with write authority on `scopeId` can inject a resource from any other scope they control. This is High severity when: (a) the assignment is used as an authorization grant, (b) the actor can supply `resourceId` through a legitimate API call, and (c) resources have different permission sets across scopes. The guard must be added at the write method level (not only at the caller), so it is enforced for all future callers.

---

## Audit Logging Required for Explicit Deny/Revocation Operations

Creating or modifying a resource that explicitly denies or revokes a permission (a deny list, a revocation entry, an exclusion rule) is a higher-consequence security event than creating a standard allow-grant. When `ILogger` is absent from the service implementing the deny operation, flag as Medium — OWASP A09:2021. The fix pattern: log at `LogInformation` with template ID, resource ID, actor ID, and count (not the full list) at the point of persistence.

---

## Pure Calculation Modules Warrant Rapid OWASP Category Disqualification

When all changed files are internal calculation or report-builder classes with no I/O, no authentication, no serialization of untrusted data, and no external calls, explicitly disqualify the inapplicable OWASP categories (injection, broken access control, authentication bypass) up-front rather than investigating each one. Document the disqualification with the structural reason ("no user-controlled input reaches this code") and spend audit time on what actually applies: exception-message contents, unchecked arithmetic, and immutability.

---

## `GetType().Name` in Exception Messages: Rating Depends on Propagation Path

An exception message containing `GetType().Name` or other internal implementation details is only a meaningful finding if the message can reach an externally visible surface (HTTP response body, log line accessible to untrusted parties). In a server-side internal system where exceptions are caught by a top-level handler and logged internally, this is Low. Before rating, trace whether the exception propagates to a public API response. If the call site is deep inside an internal calculation pipeline with no web surface, note it as a defense-in-depth Low and move on.

---

## Filter Removal on Internal LINQ Pipelines Is Not a Data Exposure Finding Without Sensitive Data

When a `.Where()` / `.Filter()` guard is removed from a LINQ chain, ask: does the data type contain credentials, PII, tokens, or sensitive business values? If the data is typed engineering values, financial calculations, or other non-sensitive domain objects flowing through an internal report builder, "previously excluded data now appears in output" is a business logic change, not a security finding. Only escalate if the data type contains sensitive fields or if the output crosses an authorization boundary.

---

## Verify Both Config Layers Before Dismissing Hardcoded Credential Findings

ASP.NET Core loads `appsettings.json` in ALL environments, then overlays `appsettings.{Env}.json`. A credential in the base file is only safe if the environment-specific file explicitly overrides it. When auditing any config file, always check `appsettings.Production.json` (and any secrets.json) before deciding a base-file credential is masked. If the override is absent, rate the finding High regardless of how obvious the password looks — any plaintext credential is exploitable if the DB is network-reachable.

---

## Permission Management Pages: `[Authorize]` Guards Authentication, Not Authorization

When a page manages permissions (role templates, access control, security settings), the presence of `[Authorize]` is a near-certain sign that only authentication has been checked — not whether the authenticated user has the required permission to manage permissions. Always look for the permission evaluator or policy handler being invoked. If neither is present, this is a High finding: any authenticated user can perform the operation. This asymmetry is especially common when a permission engine is built in the same feature slice as the UI that should consume it.

---

## IDOR Asymmetry: Read Operations Filter by Resource; Write Operations Often Don't

A common IDOR pattern in service classes: read-path methods (`GetByResource`, `ListByBoard`) accept a `resourceId` parameter and filter accordingly, while destructive/mutating methods (`Delete`, `ApplyEdit`, `Update`) accept only the record's primary key and use a bare primary-key lookup with no ownership check. Always verify the write path explicitly — do not assume it mirrors the read path. Even in single-tenant systems, this invariant should be enforced at the service boundary to prevent regression when the system evolves.

---

## Placeholder Actor Identity in Audit Trails Is a High Security Finding in Permissions Features

A `Guid.Empty`, `null`, or `"system"` placeholder for `createdById` / `actorId` in a permissions management feature is not cosmetic — it destroys the audit trail for the most sensitive operations in the system. This is High severity (A09: Security Logging and Monitoring Failures) in permissions features specifically, because the inability to attribute a permission change means escalation events cannot be investigated. If the real identity is "not yet wired," the safe default is to block the operation rather than accept a fake identity.

---

## Document-Only Invariants on High-Precedence Authorization Paths Are Structural Risk

When an authorization evaluation step depends on a caller-side invariant (e.g., "you must scope-filter these overrides before passing them"), and that invariant is enforced only by a doc comment rather than by a type property, compile-time check, or factory method, rate it Medium — not Low. The risk scales with the number of future callers and the precedence of the step in the evaluation order. High-precedence steps (e.g., Step 2 of N, evaluated before all template grants) deserve compile-time enforcement because a single caller mistake bypasses the entire downstream logic.

---

## `DisableAntiforgery()` Comment Accuracy Must Be Verified Against Form Markup

When an endpoint calls `DisableAntiforgery()` with a comment citing an `AntiforgeryToken` component, verify the Razor file actually renders `<AntiforgeryToken />`. The comment and the code can diverge over time. If the form does not include the component, the comment is misleading documentation — rate Login CSRF Medium and note the comment inaccuracy as a secondary finding.

---

## `IReadOnlyList`/`IReadOnlyDictionary` With Inline Arrays: Do Not Flag as Mutation Risk Without Checking Caller Retention

`IReadOnlyList<T>` wrapping an array passed via `new[] { ... }` is correctly immutable when no external variable retains a reference to the underlying array. Before flagging mutation risk, check whether the concrete collection is stored in any variable that outlives the wrapper construction. If the collection is always constructed inline and the only reference is through the read-only interface, immutability is effectively guaranteed. Document this as "sound pattern" rather than a finding.

---

## Convention-Only Connection String Protection in Test Harnesses Is a Low Finding

A test harness constructor that accepts `string connectionString` with no runtime validation relies entirely on callers following a convention (e.g., "always pass the ephemeral container's string"). If any caller bypasses the base class or forgets the convention, real database writes occur. Always flag this pattern as Low and recommend a lightweight guard (e.g., assert `localhost` is in the connection string) so the constraint is machine-enforced rather than documentation-enforced.

---

## 2026-05-20 — `Results.Conflict(ex.Message)` in Minimal-API Catch Blocks Is Information Disclosure

**Pattern**: In ASP.NET Core minimal-API exception handlers, `Results.Conflict(ex.Message)` and `Results.NotFound(ex.Message)` pass the raw service-layer exception message directly to the HTTP response body. Service exception messages frequently contain internal state: entity IDs, database column values, business rule context, or — in the worst case — exception messages from the underlying ORM or DB driver. This is a recurring information disclosure pattern in minimal-API codebases.

**Heuristic**: For every `catch` block in a minimal-API endpoint, check whether the caught exception's `.Message` is passed to `Results.*()`. If yes, classify as at least Low (gated-auth endpoint) or Medium (unauthenticated endpoint). Always recommend replacing the dynamic message with a fixed string and logging the full exception server-side.

**Severity guidance**: Low when the endpoint is authenticated and the message reveals only business-rule context (e.g., "machine name already registered"). Medium when the endpoint is unauthenticated or the message could reveal topology, schema names, or connection details.

---

## 2026-05-20 — C# Record DTOs in Minimal-API Endpoints Have No Automatic Validation

**Pattern**: C# `record` types bound from request bodies in ASP.NET Core minimal-API endpoints do **not** have DataAnnotations validated automatically. The model-binding infrastructure creates the record successfully even if `[Required]` fields are null or `[MaxLength]` is exceeded — validation attributes are decorative unless a validation filter or `IEndpointFilter` explicitly invokes `Validator.TryValidateObject`. This is different from MVC controller actions, where `ModelState.IsValid` applies automatically.

**Heuristic**: For any `record` DTO used as a minimal-API parameter, check whether (a) the annotations are present and (b) there is an explicit validation step before the service call. If neither exists, flag as Medium/Low depending on whether the endpoint is authenticated. Always recommend an explicit guard for null/empty required fields at the endpoint level, even if full annotation-based validation is not yet wired.

**Severity guidance**: Medium when the unvalidated field reaches a database column or an allocation-proportional operation (array length). Low when the service layer provides its own guards.

---

## 2026-05-23 — Test Readiness Globals in Production HTML Are a Low-Severity, Real Finding

**Pattern**: Interactive-server web apps (Blazor Server, React with SSR, Vue SSR) sometimes register a global JavaScript function in the production HTML shell whose sole purpose is to set a DOM attribute as a signal to Playwright / Selenium that the app is "ready." Example: `window.setCircuitReady = function() { document.body.setAttribute(...) }`. This function is called via server-side JS interop after the websocket/circuit is established. It is harmless in isolation — it only writes to the DOM — but it is unnecessary global exposure.

**Heuristic**: Look for `window.*Ready`, `window.*Signal`, `window.*Initialized` assignments in the production HTML root file. If the only consumer is E2E test code (`waitForFunction`, `waitForSelector`), classify as Low. If the function also sets an auth flag or controls UI state, escalate to Medium. Always recommend a production guard so the function is only defined in non-production environments.

**Severity guidance**: Low when the function only writes a DOM attribute. Medium if writing the attribute can bypass a UI access gate that a real user should not be able to bypass (rare, but possible in SPAs with JS-controlled routing guards).

---

## ASP.NET Core Cookie Middleware ReturnUrl Validation Is Separate From App-Level Validation

**Pattern**: When an app uses cookie auth middleware (`AddCookie`) and a custom login page reads `ReturnUrl` from the query string, there are two distinct validation chains:
1. **Middleware-constructed redirects**: When the middleware challenges an unauthenticated request, it constructs the redirect URI internally (adding `?ReturnUrl=<encoded current path>`). The middleware's post-login redirect uses `LocalRedirectPreserveMethod`, which internally applies `IsLocalUrl` validation. `IsLocalUrl` in ASP.NET Core does correctly reject `//attacker.com`.
2. **App-level consumption**: The login page component independently reads `ReturnUrl` from the query string via `[SupplyParameterFromQuery]` or similar binding. This is a completely separate code path that applies the app's own guard. If the app's guard is broken (e.g., uses `RelativeOrAbsolute`), the middleware's correct validation does **not** protect it — an attacker can directly craft a URL with a malicious `ReturnUrl` and bypass the middleware's validation path entirely.

**Heuristic**: Do not assume that correct middleware-side ReturnUrl handling protects the login component. They are independent. Audit both separately.

---

## `CookieSecurePolicy.SameAsRequest` Is Insecure Behind an HTTP Reverse Proxy

**Pattern**: ASP.NET Core defaults `CookieAuthenticationOptions.Cookie.SecurePolicy` to `CookieSecurePolicy.SameAsRequest`. When the app runs on plain HTTP (e.g., `http://localhost:5000`) behind a TLS-terminating reverse proxy, all Kestrel-visible requests are HTTP. Without `UseForwardedHeaders()` (or equivalent forwarding configuration), Kestrel does not know the upstream connection is HTTPS. Auth cookies are therefore issued without the `Secure` attribute.

**Heuristic**: When auditing a cookie auth setup, always check: (a) does `options.Cookie.SecurePolicy = CookieSecurePolicy.Always` appear explicitly? and (b) is `app.UseForwardedHeaders()` registered before `app.UseAuthentication()`? If neither is present and the production deployment model uses a reverse proxy, flag as Medium.

**Severity**: Medium (not High) in typical deployments because the production proxy usually terminates external TLS — session cookies are never transmitted in cleartext to an external attacker in the common case. Escalate to High if the app is internet-facing without TLS termination.

---

## IDOR Guards: Ownership Key AND Resource Type Discriminator Must Both Be Checked

When an IDOR guard checks a single dimension (e.g., `resource.OwnerId == requestedOwnerId`) but the storage table holds multiple resource types distinguished by a type discriminator field (e.g., a `Scope`, `Kind`, or `Type` column), the guard is incomplete. A record of type B with a matching owner ID passes the guard designed for type A, allowing a cross-type write via the wrong code path.

**Heuristic**: When a new ownership parameter is added to a write-path method, immediately ask: "Are there other values of the type-discriminator field that could pass this check?" If yes, add the type condition to the guard. This applies to any multi-type storage table where type and owner are independent dimensions.

**Severity**: Medium — typically exploitable only when the attacker can create records of the unintended type via a separate code path, but that capability may exist and evolve independently.

**Spec vs. implementation divergence signal**: If the feature spec requires a compound check (`ownerId AND type`) but the input packet specified only one dimension, surface the inconsistency explicitly. Do not silently accept the narrower implementation — one of the two documents must be updated before merge to avoid treating the absent check as a regression in the next audit cycle.

---

## Successful Writes in Permission-Management Services Require Success-Path Logging

Standard permission-management audit logging focuses on creation events and security violations (e.g., IDOR blocks). However, editing an existing permission set — role template permissions, ACL entries, policy records — is the _highest-consequence_ write in most permissions systems: a single edit simultaneously changes the effective permissions of every entity currently assigned to that template.

**Heuristic**: For any service that has `CreateAsync` logging AND a `ApplyEditAsync`/`UpdateAsync`/`EditAsync` path, verify the update path logs on _success_, not just on failure. If the success path is silent, flag as Medium (A09:2021). The absence is especially dangerous because the create-path log creates a false impression that the mutation trail is fully covered.

**What to log** (on success): resource identifier, owner/board identifier, new item count (not the items themselves), and affected assignee/member counts. Never log the full list of permission strings — identifiers and counts only.

---

## `LINQ.ToDictionary()` on Caller-Supplied Collections Throws on Duplicate Keys

When `LINQ.ToDictionary(keySelector)` is called on a caller-supplied list in a service method, duplicate values for the same key throw `ArgumentException: An item with the same key has already been added` unconditionally and unhandled. This is inconsistent with other guard patterns in the same method that throw typed, intentional exceptions with explicit messages.

**Heuristic**: For every `ToDictionary` call on a parameter passed in from outside the service boundary, add a uniqueness pre-check or use `ToLookup` (which tolerates duplicates). Flag the absence as Low in any service where the caller is an external component (UI, API); the attacker can trigger a server error with a crafted duplicate-key payload.

**Fix pattern**:
```csharp
var seenIds = new HashSet<TKey>();
if (items.Any(d => !seenIds.Add(d.Key)))
    throw new ArgumentException("Duplicate key entries found.", nameof(items));
var map = items.ToDictionary(d => d.Key);
```

---

## When to Append an Entry

Only append if the session revealed something surprising, a false positive pattern, or a finding worth noting for future security reviews. If the review ran smoothly using existing knowledge, skip the update.

---

## 2026-05-18 — SignalR Authentication Token in URL Query String

**Pattern**: When auditing SignalR hub connections, always check whether the authentication token is passed as a URL query parameter vs. an `Authorization: Bearer` header. Query parameters appear in server access logs, proxy logs, and process-level network monitors in plain text — bypassing all `ToString()` redaction and `[JsonIgnore]` protections applied elsewhere. The correct pattern for SignalR is to use `AccessTokenProvider` on `HubConnectionBuilder`, which causes the token to be sent as a header during the HTTP negotiate phase.

**Heuristic**: Search for `.WithUrl(` calls in any SignalR client code. If the URL is built with string interpolation that includes a token, credential, or key, flag it as High — the token will appear in server access logs unconditionally.

**Severity guidance**: High when the token is long-lived (machine registration, API key). Medium when the token is short-lived and per-session.

---

## 2026-05-18 — LLM Dispatch Architecture: Prompt Injection Is an Inherent Risk

**Pattern**: In any system that takes user-controlled text from a data store (task titles, descriptions, comments) and constructs an LLM prompt from it without sanitization, prompt injection is present by design. The risk is amplified when the agent runs with permissive flags (equivalent to `--allow-all-tools`, `--no-ask-user`) that remove human confirmation. The standard mitigation is a fixed system-level preamble that explicitly scopes the agent and tells it to ignore instructions embedded in data fields.

**Heuristic**: Locate the prompt-building code. Check: (1) does it include user-authored fields? (2) is there a fixed system instruction that precedes those fields and cannot be overridden? (3) are agent tool permissions minimized? Flag as **Medium** for internal tools with authenticated task creation; **High** if task creation is externally accessible; **Critical** if the agent has shell or filesystem access with unrestricted tool permissions.

---

## 2026-05-08 — Scope-Relative Severity for Absent Auth

**Pattern**: When a personal/local-only application has no authentication, resist classifying this as Critical/High at face value. Apply a deployment-context matrix: localhost-only = Medium; LAN-accessible = High; internet-facing = Critical. Flag it clearly with the escalation condition rather than assigning worst-case severity for a tool that is demonstrably scoped to single-user local use.

**Heuristic**: Check whether the architectural intent (personal tool, no multi-user model) is apparent from the domain model, DI registration, and README before assigning severity to missing auth.

---

## 2026-05-08 — Binary Database Files in Git

**Pattern**: Design-time or migration-scaffolding database files (SQLite `.db`, Access `.mdb`, etc.) frequently appear committed to source repositories. They are binary blobs that do not belong in git: they can accumulate real data, cause merge conflicts, and bloat history. Always check `git ls-files` for `*.db` patterns during security reviews. Classify as Medium if only schema is present, escalate if real data is detected.

---

## 2026-05-19 — Blazor `@` Binding Auto-Encodes: XSS Via Toast/Label Content Is Not a Valid Finding

**Pattern**: In Blazor (Server, WASM, Hybrid), the standard `@expression` syntax in `.razor` files applies HTML encoding unconditionally before writing to the DOM. A `@toast.Message` or `@entry.Email` binding cannot produce XSS regardless of what the string contains — it will be rendered as literal text, not markup. This applies to both text node interpolation and attribute values bound via `@`.

**Exception**: XSS is still possible if the developer explicitly opts out via `@((MarkupString)rawHtml)` or `@Html.Raw(...)`. These require deliberate use of `MarkupString` or `IHtmlContent`. Always grep for `MarkupString` in any Blazor codebase if XSS is a concern.

**Heuristic**: Start Blazor XSS analysis by searching for `MarkupString` and `Html.Raw` rather than examining individual `@expression` bindings. If neither exists, the XSS surface is essentially zero.

---

## 2026-05-19 — System.Text.Json Typed Deserialization Is Safe Against Gadget-Chain Attacks

**Pattern**: `JsonSerializer.Deserialize<T>()` with a concrete or generic type target does not support polymorphic type instantiation by default. An attacker cannot inject a `$type` field to force construction of an arbitrary .NET type — System.Text.Json ignores unknown properties and deserializes only into the declared type. The risk only re-opens when `[JsonDerivedType]` attributes or a custom `JsonConverter`/`DefaultJsonTypeInfoResolver` with `IncludeFields = true` and broad type resolution is present.

**Heuristic**: For any `JsonSerializer.Deserialize` call, only escalate to a deserialization-gadget finding if `[JsonDerivedType]`, `JsonConverter`, or polymorphic resolver configuration is present. Grep for those patterns first as a rapid-disqualification shortcut.

---

## 2026-05-19 — Unvalidated Path Parameters in Service Method Signatures Are a Latent Risk Pattern

**Pattern**: Service methods that accept a folder or file path as a `string` parameter and use it directly in `Path.Combine` + write operations have no guaranteed trusted-root at the method boundary. Even when all current callers supply trusted values (e.g., from `Directory.EnumerateDirectories`), the method signature is an open invitation for future callers to supply an arbitrary path. The risk is latent, not present.

**Heuristic**: When a `Save*` or `Write*` method takes a path parameter and the service has a concept of a "configured root" (e.g., from settings), always check whether the method asserts `Path.GetFullPath(paramPath).StartsWith(rootPath)`. If not, flag as Low with a concrete remediation snippet. Do not escalate beyond Low unless a current caller is actually untrusted.

**Severity guidance**: Low for internal tools where all callers are in the same process. Medium if the path parameter is derived from a network payload or user-submitted form value.

---

## 2026-05-18 — Fire-and-Forget Async in MVVM Message Receivers Is a Dispatch-State Risk

**Pattern**: In CommunityToolkit.Mvvm (and similar MVVM frameworks), `IRecipient<T>.Receive()` is synchronous by interface contract. When a message triggers async work, the idiomatic result is `_ = SomeAsyncMethod()` — a discarded task. This silently swallows any exception thrown by the async path. If the async work updates security-relevant in-memory state (e.g., dispatch approval flags, task status), a failure leaves the ViewModel in a stale, potentially misleading state with no error signal to the user.

**Heuristic**: During any security review of a CommunityToolkit.Mvvm (or similar) codebase, scan all `IRecipient<T>.Receive` implementations for `_ = ` patterns. If the discarded task touches dispatch, approval, or authorization-adjacent state, classify as Medium and recommend a wrapping catch that resets the card/entity to a safe state on failure.

**Severity guidance**: Medium when the stale state is security-relevant (dispatch approval, status transitions). Low when the stale state is purely cosmetic (display label, count).

---

## 2026-05-18 — MVVM Dispatch Approval Gates: ViewModel Should Assert Pre-Conditions

**Pattern**: In MVVM dispatch approval flows, the ViewModel layer is the last place where domain context (task state, category config) is available before a service call. When the service is the only enforcement gate for a safety-critical operation (autonomous dispatch), any regression or future gap in the service layer is unchecked. The ViewModel should assert readily-available pre-conditions (e.g., verifying the domain entity's own flag that permits the operation) before calling the service.

**Heuristic**: For any approval or dispatch-enabling method in a ViewModel, ask: "Does the ViewModel have access to a property that would immediately disqualify this call?" If yes, assert it before the service call — even if the service will also enforce it. The cost is one `if` statement; the benefit is defense-in-depth for an irreversible operation.

**Severity guidance**: Medium for local tools with trusted callers. High if the ViewModel is invoked via an API or inter-process boundary where the caller cannot be trusted.

---

## 2026-05-12 — CSS Injection via Inline Style Attribute with User-Controlled Color Field

**Pattern**: Color fields (hex color pickers in UI forms) that feed into inline `style="background-color: @Color"` attributes are a CSS injection vector. Blazor's HTML encoding neutralizes HTML-special characters but does NOT prevent CSS token injection (e.g., `#fff; display:none`). When auditing, always trace `color`-type fields from their origin (user input / DB) through to any `style=` attribute usage. Validate with a strict hex color regex at the service layer.

**Heuristic**: Check all `style=` attribute expressions in Razor files for any dynamic value sourced from user data. CSS injection is easily missed because the obvious XSS vectors (script tags, event handlers) are absent.

---

## 2026-05-12 — Hardcoded Fallback Connection Strings in Dev-Time Factory and CLI Bootstrap

**Pattern**: Design-time EF Core factories (`IDesignTimeDbContextFactory`) and CLI tools that bootstrap their own DI often contain hardcoded fallback connection strings so they work "out of the box" during development. These fallbacks routinely end up committed to git and can carry production-equivalent credentials if password hygiene is poor. During security reviews, always check `IDesignTimeDbContextFactory` implementations and CLI `Program.cs` bootstrap sections for `??` fallback connection strings.

**Heuristic**: Fail fast with an explicit error message when the environment variable or config is absent — do not provide a default that makes credentials optional.

---

## 2026-05-12 — `ProcessStartInfo.Arguments` vs `ArgumentList` for Subprocess Safety

**Pattern**: When a C# codebase spawns external processes with `UseShellExecute = false`, shell injection is not a risk. However, if `ProcessStartInfo(fileName, arguments)` is used with a single string `arguments`, and any segment of that string is constructed from config or user data without quoting, argument-splitting bugs can occur (spaces in values, unexpected extra args). The safe alternative is `ProcessStartInfo.ArgumentList` which passes each argument as a separate element without any quoting/parsing. Always prefer `ArgumentList` over the string `Arguments` property when constructing arguments programmatically.

---

## 2026-05-12 — Pure Internal Domain Logic: OWASP Non-Applicability Pattern

**Pattern**: For changes that are entirely within a deep-pipeline calculation engine (no network, no I/O, no external API surface, no user input crossing a trust boundary), the majority of the OWASP Top 10 is structurally non-applicable. The meaningful security question for this class of change is: "Can a flow-skip or short-circuit produce an unsafe domain output?" — not injection, access control, or cryptography.

**Heuristic**: When all inputs to a changed class are in-process domain objects set by prior trusted pipeline stages, write concise "Not applicable" explanations for each OWASP category rather than forcing speculative findings. For flow-control changes specifically, verify: (1) the skip is bounded (does not persist indefinitely), (2) a fallback path ensures correct output on subsequent iterations, and (3) unit tests cover the boundary conditions of the skip predicate.

---

## 2026-05-12 — Flow Exit Log Strings in Engineering Tools Are Not Sensitive Data

**Pattern**: Internal flow frameworks in engineering tools use descriptive string literals as exit/skip reasons. These are execution traces, not user-facing messages, and contain no sensitive data.

**Heuristic**: Do not classify these as information disclosure findings unless the framework demonstrably surfaces them externally (API response, browser, log shipped off-machine). At most, note them as Low/informational with the escalation condition.

---

## 2026-05-13 — `Path.Combine` Does Not Sanitize Inputs — Always Sanitize String Paths From Non-Literal Sources

**Pattern**: `Path.Combine(baseDir, untrustedSegment)` on .NET has two path-traversal behaviors: (1) a relative `..`-containing segment traverses above the base directory (Windows resolves `..` at the OS level during `Directory.CreateDirectory` / `File.Open`), and (2) an absolute-path segment completely discards the base directory. This applies even when the data source is "trusted" (internal DB, internal API). A string field in a database is still a string and can contain path characters if data quality is not enforced at the schema level.

**Heuristic**: Any string that is not a compile-time literal and is used in `Path.Combine` requires sanitization — strip `\`, `/`, `:`, and `..` sequences before use. Check whether the code applies the same sanitization consistently to all segments (not just some of them).

**Severity guidance**: For dev/diagnostic tools with an internal trusted data source, classify as Medium (not High), document the low practical exploitability, and provide the one-line fix. Reserve High for tools with external user input at this boundary.

---

## 2026-05-16 — User-Editable Local Settings File as Identity Source Is a Spoofing Vector

**Pattern**: When a desktop application persists user identity (e.g., Windows username) in a plaintext local settings file and that identity is then used in file path construction or cross-user write operations, the settings file becomes an impersonation attack surface. Even though the file is "local" and "user-scoped," any process running as that user (or any user with access to `%APPDATA%`) can alter the identity field. The stored username then controls which files are written on behalf of whom.

**Heuristic**: At startup, compare the stored identity field against `Environment.UserName` (or equivalent OS-sourced identity). If they diverge, reset to the OS value and log a warning. This is a low-ceremony guard that closes the impersonation path without adding authentication infrastructure. Check: (1) what fields in the settings model control write destinations, (2) whether the settings file is writable by the current user without elevation, and (3) whether there is any OS-sourced assertion that would detect tampering.

**Severity guidance**: Medium for internal dev tools (write target is an internal shared folder). High if the write target is a customer-facing or production data store.

---

## 2026-05-16 — C# Record `ToString()` Leaks All Positional Properties Including Tokens

**Pattern**: C# records auto-generate a `ToString()` that includes all positional parameters by name and value. When a record contains a token, password, or secret field, any log call that passes the record (e.g., `logger.LogDebug("{record}", myRecord)`) or any exception message that calls `.ToString()` will dump the secret verbatim. This is especially dangerous for dispatch/auth records that combine non-sensitive routing data (task ID, machine ID) with sensitive token fields in a single type.

**Heuristic**: During any security review, scan for `record` types that contain fields named `Token`, `Secret`, `Key`, `Password`, `Credential`, or `Auth`. Verify whether `ToString()` is overridden or whether the type has a `[SensitiveData]` attribute. If neither: flag as High and recommend a redacted `ToString()` override and/or a separate credential type.

**Severity guidance**: High when the token is persistent (registration token); Medium when the token is short-lived (per-dispatch token).

---

## 2026-05-16 — Persistent Credentials on Domain Entities Will Serialize to API Responses

**Pattern**: Domain entities (EF Core classes that are also POCOs) are often serialized directly in API responses, especially in CRUD-style admin endpoints. A credential or token field on a domain entity will appear in any response that serializes that entity unless `[JsonIgnore]` or a projection DTO is explicitly applied. The domain layer does not control serialization — so a credential on a domain entity is always one forgotten DTO away from being exposed.

**Heuristic**: Flag any domain entity that carries a field semantically equivalent to a password or API key (named `Token`, `Secret`, `Key`, `RegistrationToken`, `ApiKey`, etc.) as a High finding. The fix pattern is: store a hash only; return the raw value once at creation; never include it in the entity used for listings.

---

## 2026-05-16 — Deserialized Fields That Are Never Read Represent Unnecessary PII Surface

**Pattern**: Model classes that deserialize JSON from a shared or persisted source sometimes contain fields (e.g., `Email`, `PhoneNumber`) that were added speculatively for future use but are never referenced by any service, view, or log. These fields still pass through memory on every deserialization, increase the PII footprint in memory dumps, and create schema coupling to the stored file.

**Heuristic**: During security review, grep for model fields that hold email, phone, SSN, or other PII-adjacent names. Cross-reference against all usages — if the field is never read after deserialization, classify as Low and recommend `[JsonIgnore]` or model removal. Document the finding so future developers don't inadvertently add a feature that reads the unused field without reassessing the privacy implications.

---

## 2026-05-20 — Browser `<a href>` Download Links Pointing to Machine-Token-Authenticated Endpoints Are Always Broken

**Pattern**: In systems that have two separate authentication models — one for human browser users and one for machine/agent callers — it is easy to accidentally create UI download links that point to machine-only endpoints. A Blazor (or any server-rendered) UI that renders `<a href="/api/resource/download">` causes the browser to issue a plain GET request with no custom `Authorization` header. If the target endpoint is guarded by a machine bearer-token filter, the browser request always returns 401 Unauthorized — and the user experiences a broken link with no error message in the UI.

**Heuristic**: For any download link rendered as a standard HTML anchor in a component that also stores machine-token credentials elsewhere, trace the link target to its endpoint and verify the auth requirement. If the endpoint requires a token that the browser does not automatically supply, the download is broken. The correct fix is to route the download through the authenticated Blazor circuit (call the service from a component codebehind method, push bytes to the browser via JS interop) rather than embedding a direct API URL.

**Severity guidance**: Medium — it is a broken access path for legitimate users, not an unauthorized-access path. Escalate to High if the broken download means critical data is inaccessible and there is no alternative retrieval path.

---

## 2026-05-22 — Verify `??` Fallback Reachability in Multi-Layer Config Override Chains

**Pattern**: CLI tools and bootstrap code often contain hardcoded fallback connection strings using the `??` null-coalescing operator (e.g., `config.GetConnectionString("X") ?? "hardcodedFallback"`). When a new environment-specific config file is added (or an existing one is extended), the hardcoded fallback may become permanently unreachable — the environment-specific file provides a non-null value even when it only contains a placeholder. The credential security analysis is fundamentally different depending on reachability: if the fallback is unreachable, it never exposes credentials; if it is reachable, it can silently connect with dev credentials in unexpected environments.

**Heuristic**: When auditing a hardcoded fallback connection string, trace the full config loading chain: base file → environment-specific file → environment variables. Ask: "For every environment the tool is designed to run in, can `config.GetConnectionString(...)` return null?" If the environment-specific file has a non-null value for the key (even a placeholder string), the `??` fallback is dead code for that environment. Confirm the fallback is dead before classifying it as a live credential exposure risk. Conversely, if the fallback IS reachable, flag it as Low–Medium and recommend replacing it with a hard failure.

**Severity guidance**: If the fallback is unreachable (confirmed via config-chain analysis): Low, document as dead code. If the fallback is reachable in any production code path: Medium for local tools, High for server-deployed tools.

---

## 2026-05-28 — `Uri.IsAbsoluteUri` Does Not Catch Protocol-Relative Open Redirects

**Pattern**: A common `ReturnUrl` / open-redirect guard uses `Uri.TryCreate(url, UriKind.RelativeOrAbsolute, out var uri)` followed by `return !uri.IsAbsoluteUri`. This check **does not** protect against protocol-relative URLs such as `//attacker.com`. .NET's `Uri` parser classifies `//attacker.com` as a *relative* URI (no scheme present), so `IsAbsoluteUri` returns `false` and the URL passes the guard. Browsers, however, interpret `//attacker.com` as `https://attacker.com` — a fully external destination. An attacker crafts a link like `/auth?ReturnUrl=%2F%2Fattacker.com`, the user authenticates legitimately, and is immediately redirected to the attacker's site.

**Heuristic**: Any `IsRelativeUrl` / `IsSafeReturnUrl` guard must include an explicit string-level check that the URL starts with exactly one `/` and does NOT start with `//` or `\/`. The `Uri` API is insufficient as the sole validator:

```csharp
// Correct: reject protocol-relative and other ambiguous prefixes BEFORE Uri parsing
if (url.Length < 2 || url[0] != '/' || url[1] is '/' or '\\')
    return false;
if (!Uri.TryCreate(url, UriKind.Relative, out _))
    return false;
return true;
```

Prefer `UriKind.Relative` (not `UriKind.RelativeOrAbsolute`) in the secondary `TryCreate` call — the stricter parse mode rejects absolute URIs outright rather than returning an ambiguous result.

**Severity guidance**: Critical. The exploit requires only a crafted link, no authentication, and is fully reliable. Phishing/credential-harvesting is the immediate impact.

---

## 2026-05-28 — Security Headers Middleware Placed After Auth Middleware Misses Redirect Responses

**Pattern**: In ASP.NET Core middleware pipelines, a response can be committed (headers sent) before a later middleware runs. When the authentication middleware issues a 302 redirect to a login page, it writes the response directly — before any middleware registered *after* it can add security headers. If the security-headers middleware is placed after `UseAuthentication`, the redirect response carries none of the headers (no `X-Frame-Options`, no `X-Content-Type-Options`, no CSP). This means the redirect URL — which contains the `ReturnUrl` parameter — is framing-vulnerable.

**Heuristic**: Register security-headers middleware as early in the pipeline as possible: after HTTPS redirect, before all authentication. Treat the pipeline position of security headers as a critical correctness concern, not just style preference.

**Severity guidance**: Medium. Clickjacking on a redirect response leaks the `ReturnUrl` to a framing parent, which may contain a sensitive path. Not an authentication bypass, but reduces the defense-in-depth posture for the login flow.

---

## XML Doc Alone Is Insufficient for Privilege-Flag Enforcement — Factory Method Is the Structural Gate

The existing lesson "Privilege-Flag POCOs: Caller Trust Is the Primary Attack Surface" says to flag "the absence of XML doc guidance (or a factory method)." In practice, XML doc is necessary but not sufficient. When an authorization context POCO has correct XML doc annotations ("Must be derived from the evaluator — never hardcoded") but no factory method, the constraint is documentation-only: any caller can set the flags to `true` in an object initializer with no compile-time error or warning.

**Refined rule**: When reviewing a privilege-flag POCO, treat XML doc guidance as a minimum floor and a factory method (or private constructor) as the required structural ceiling. If doc exists but no factory method exists, the finding is still High: rate it as "High — structural enforcement absent, documentation only." Rate it as closed only when a factory method or private constructor makes it impossible to construct the context without calling the evaluator.

**Severity guidance**: High when no factory method exists, regardless of whether XML doc is present. Medium only after a factory method is introduced and the remaining risk is that tests may still construct the object directly using a test-specific override.

---

## Collection Input Validation: Null Elements Cause `NullReferenceException`, Not `ArgumentException`

When a service validates a string collection with `collection.Any(p => p.Length > N)`, a null element in the collection throws `NullReferenceException` on `p.Length`, not `ArgumentException`. Under nullable reference types (`<Nullable>enable</Nullable>`), callers receive a compile-time warning for null string elements, but nothing prevents null at runtime (e.g., deserialized from JSON with a null array member, or a collection constructed dynamically). The validation contract — "reject invalid input with `ArgumentException`" — is silently violated.

**Heuristic**: In any service method that validates a collection with a per-element property check (`Length`, `StartsWith`, `Contains`), add a null-element guard before the property check:
```csharp
if (items.Any(p => p is null))
    throw new ArgumentException("Elements must not be null.", nameof(items));
if (items.Any(p => p.Length > 200))
    throw new ArgumentException("Elements must not exceed 200 characters.", nameof(items));
```

**Severity guidance**: Medium when the collection comes from an external/deserialized source (the null can be injected). Low when the collection is always constructed in controlled server-side code where nulls are structurally impossible. Always flag regardless — the wrong exception type breaks caller contracts and may propagate through error middleware unexpectedly.

---

## Mutations on Shared Permission Sets Require Audit Logging More Than Creation Does

Standard permission-management audit logging focuses on creation events. However, editing an existing permission set (role template, ACL, policy record) is higher-consequence than creating one: a single edit simultaneously changes the effective permissions for every entity currently assigned to that template. When auditing write paths in a permissions system, check that _edit_ operations have at least as comprehensive logging as _create_ operations. Log counts and identifiers only — never the permission string values themselves.

**Heuristic**: For any service that has `CreateAsync` logging and an `ApplyEditAsync` or equivalent update path, verify the update path also logs. If it does not, flag as Medium (A09:2021) regardless of whether a create-path log exists. The absence is most dangerous precisely because the create-path log creates a false impression that the mutation trail is covered.

---


## Structured log property names for security events must unambiguously identify the data type
**Category**: Process/Model

When a structured log message is emitted as part of a security control (e.g., an access-denial event, an IDOR block, an audit trail write), every named property in the template must be unambiguous about whether it represents a resource identifier or a user/principal identifier. A property named `OwnerId` is polysemous: in most codebases "owner" can refer to either the resource that owns another resource (a container, a scope, a tenant) OR the user who created/owns a resource. In a security event log, callers building monitoring queries or SIEM rules will read property names as a shared vocabulary — a misread property name means the wrong data type is used in a filter. **Rule:** For any new structured log property in a security-critical event, run the name against the codebase's existing vocabulary for user-identity fields (e.g., `CreatedById`, `PrincipalId`, `UserId`) and resource-identity fields (e.g., `ResourceId`, `ContainerId`, `ScopeId`). If the proposed name could be interpreted as either, suffix with the concrete type (e.g., `{OwnerContainerId}` instead of `{OwnerId}`). Because security log property names are a shared contract between code and monitoring infrastructure, renaming is cheapest when the log message is new. Flag the ambiguity as Low and note that the rename cost is zero before the message reaches any dashboard or SIEM rule.

---

## Copy-pasted security guards with a known pending spec change are Medium, not Low
**Category**: Process/Model

When the same security guard block is copy-pasted N times and there is a known, documented spec gap or pending requirement change that will require modifying that guard, the DRY finding is **Medium** — not Low — even if every current copy is correct and the code is passing all tests. The severity is driven by the pending change multiplier: implementing the spec change requires N atomic edits instead of one. A missed edit produces a security inconsistency (N-1 methods guard correctly, one does not) that is undetectable at compile time and may not have a test that distinguishes the partial-fix state from the complete-fix state. **Rule:** Before rating a copy-paste DRY finding, check the issue tracker or Requirements/Correctness audits for any open spec gap on the same method or guard pattern. If one exists, escalate from Low to Medium and name the pending change explicitly in the finding. The fix recommendation should always suggest extracting to a single authoritative site (private method, shared helper) before the spec change is implemented, so the spec change is made once.

---

## Matched security pairs of identical literals must be rated Medium regardless of cosmetic simplicity
**Category**: Process/Model

When the same literal appears in two places where one is a security-behavior mirror of the other — specifically, where the correctness of a security property (e.g., constant-time behavior, consistent hash strength, matching key lengths) depends on both literals remaining equal — the DRY violation is a **security maintenance trap**, not a cosmetic style issue. The scenario to watch for: a "real" code path that uses a numeric constant (e.g., hash work factor, key size) and a "dummy" or "sentinel" code path that must use the same constant for security equivalence. A future change to one without the other silently degrades the security property. **Rule:** Two identical literals that are a security-correctness pair = Medium, regardless of how trivial the extraction is.

---



## Lesson 003 — Missing Rate Limiting on BCrypt Endpoints Is Always High Severity

Any endpoint that invokes BCrypt (or similar intentionally-slow CPU operations like Argon2 or PBKDF2) without rate limiting is a CPU exhaustion DoS vector. This is High severity regardless of codebase size or traffic. Always check for `RequireRateLimiting(...)` on login/signup endpoints. Absence = High finding.

---

