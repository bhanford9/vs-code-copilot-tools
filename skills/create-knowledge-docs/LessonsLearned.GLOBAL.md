# LessonsLearned.GLOBAL.md — create-knowledge-docs

Process and workflow observations applicable across any use of this skill.
Only add entries when something was hard, slow, surprising, or went wrong.
Do not document sessions that went smoothly.

---

## Generic Skills Must Use Fully Synthetic Examples

Category: Process/Model

Skill files that contain examples drawn from a real project — even theoretical examples that mirror a real system — are a data protection violation and require a follow-up scrubbing session.

- DO use completely invented, generic examples: payment gateways, schedulers, auth flows, queue systems.
- DON'T use domain terms, system names, or concepts from any real project.
- When in doubt, ask: could a reader identify the project from this example? If yes, replace it.

---

## Onboarding Transcripts Are High-Generalization Sources — Treat Specific Claims as TODOs

Category: Process/Model

When the documentation source is a meeting transcript (especially an onboarding or teaching session), speakers routinely simplify. Specific numbers and categorical claims from a teaching conversation are often approximations, not authoritative facts. Writing them as stated facts into reference documentation creates incorrect docs that require a follow-up correction pass.

Examples of what went wrong:
- A count stated conversationally (e.g., "~50 event types") was written as a fact in a heading, but the actual count varies by context
- A simplified formula (e.g., `RecordKey = type + source + component`) was written as a complete definition, but the real structure has additional fields
- Named examples of domain-specific processing steps were listed without being verified against the codebase

Rule:
- If the source is a meeting/onboarding transcript, **any specific number, count, or formula** stated conversationally should be written as `> 📝 TODO: Verify — taken from onboarding discussion, may be a simplification` rather than stated as fact.
- Architectural descriptions (how things work conceptually) from onboarding transcripts are generally trustworthy. Specific quantities and exhaustive enumerations are not.
- DO: capture the concept accurately. DON'T: promote the approximate number into a heading or authoritative statement.
