# Security Audit Skill

## Skill Metadata

**LessonsLearned**:
- Read before starting: `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/security/LessonsLearned.GLOBAL.md`
- Read if present on disk: `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/security/LessonsLearned.md`
- Update after the audit using the lessons-learned skill

**Output file**: `/code-review/security-audit.md`

**Audit report template**: Already in your context from Phase 0. This auditor uses the standard compact format with these finding block fields between `**Where**:` and `**Issue**:`:
```
**Category**: {Injection | AccessControl | SensitiveData | Cryptography | InputValidation | Misconfiguration | Authentication}
**OWASP**: {e.g., A03:2021 – Injection}
```
Use `## Clean` to list OWASP categories with no findings (e.g., "Injection, Cryptography, Authentication").

---

<workflow>

## 0. Read LessonsLearned

Read the LessonsLearned files listed in Skill Metadata above. Apply any recorded patterns.

## 1. Evaluate Security Dimensions

### Injection Risks
**Can untrusted input reach dangerous execution paths?**
- **SQL Injection**: Raw string concatenation into queries? Parameterized queries used consistently?
- **Command Injection**: User-controlled input passed to shell commands, `Process.Start`, or similar?
- **Path Traversal**: User-supplied file paths used without canonicalization/validation?
- **XML/JSON Injection**: External data deserialized without schema enforcement or type restrictions?
- **Expression Injection**: User input evaluated as an expression, template, or formula?

### Broken Access Control
**Are authorization checks correct, complete, and at the right layer?**
- **Missing Authorization**: Operations that modify or expose data with no access check?
- **Privilege Escalation**: Can a lower-privilege caller trigger a higher-privilege code path?
- **IDOR (Insecure Direct Object Reference)**: IDs or keys from user input used to retrieve records without ownership verification?
- **Bypasses via Parameter Manipulation**: Can a caller skip a guard by omitting or altering a parameter?
- **Authorization After Data Fetch**: Is authorization checked before data is loaded, or only after — leaking existence?

### Sensitive Data Exposure
**Is sensitive information adequately protected?**
- **Logging**: Are passwords, tokens, PII, or secrets written to logs?
- **Serialization**: Are sensitive fields excluded from serialization output?
- **Error Messages**: Do exception messages or error responses reveal internal structure, stack traces, or sensitive values?
- **Hardcoded Secrets**: API keys, credentials, or tokens hardcoded in source or config files?

### Cryptographic Issues
**Is cryptography used correctly?**
- **Weak Algorithms**: MD5/SHA1 for integrity or password hashing? DES/3DES for encryption?
- **Predictable Randomness**: `Random` or `Math.random()` used where `SecureRandom`/`RandomNumberGenerator` is required?
- **Missing TLS Validation**: Certificate validation disabled?

### Input Validation
**Are inputs validated at system boundaries?**
- **Missing Boundary Validation**: Public API or command-line entry points that accept data without size, range, or format checks?
- **Trust Boundary Violations**: External data used as-is without sanitization?
- **Deserialization of Untrusted Data**: Polymorphic or unconstrained deserialization of external payloads?

### Security Misconfiguration
**Are defaults and configurations secure?**
- **Insecure Defaults**: Features enabled by default that should require explicit opt-in?
- **Debug/Dev Flags in Production Paths**: Debug logging, verbose errors, or dev-only settings reachable via production code paths?

### Authentication
**Are authentication boundaries maintained?**
- **Authentication Bypass**: Code paths that can be reached without a valid authentication context?
- **Weak Token Validation**: JWT signatures not verified? Token expiry not enforced?

## 2. Identify Security Issues

Categorize by severity:

### 🔴 Critical - Exploitable; must fix before merge
- Direct injection vectors with untrusted input
- Authentication or authorization bypass
- Hardcoded credentials in source
- Sensitive data (credentials, PII) written to logs or error responses
- Deserialization of untrusted data with type gadgets

### 🟠 High - Significant risk; should fix before merge
- Missing input validation at system boundaries
- Privilege escalation via parameter manipulation
- Weak cryptography for security-sensitive operations
- IDOR without ownership check
- Sensitive fields included in serialized output

### 🟡 Medium - Should address soon; reduces attack surface
- Error messages revealing internal structure
- Debug/dev paths reachable in production code
- Missing TLS validation in non-critical paths
- Predictable randomness in low-sensitivity contexts

### 🟢 Low - Defense-in-depth improvements
- Missing security headers
- Dependency with CVE at low severity
- Configuration hardening opportunities

## 3. Write Security Audit Report

Write findings to `/code-review/security-audit.md` using the audit report template (already in your context from Phase 0). Use the finding block fields defined in Skill Metadata above.

Each finding must include a **concrete exploit scenario or attack vector** in the `**Issue**:` field.

## 4. Update LessonsLearned

Write qualifying workflow process improvements to `LessonsLearned.GLOBAL.md` at `~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/security/`.

**Do NOT write**:
- Codebase-specific observations, class names, method names, or file paths from the reviewed codebase
- Code-finding patterns, severity calibrations, or findings about this particular code
- Anything that would not apply word-for-word to a review of a completely different codebase

`LessonsLearned.md` (the per-repo local file) **should remain empty**.

</workflow>

<conventions>
Shared output conventions are already in your Phase 0 context (inlined in REVIEW-Auditor.agent.md).
</conventions>
