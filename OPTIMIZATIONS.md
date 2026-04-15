# System Optimization Backlog

Potential improvements to the overall copilot-configs tooling system, identified April 2026.

---

## Items

- [ ] **#2 — Add `/review-lessons` prompt for LessonsLearned escalation**  
  The `lessons-learned` SKILL.md defines a 3-strikes → hook escalation path, but nothing triggers a review of which lessons have crossed that threshold. Create a `/review-lessons` prompt that reads all `LessonsLearned.md` files, finds entries with 3+ recurrence signals, and surfaces promotion/hook candidates.

- [x] **#3 — Remediate documentation gaps found in FEATURES-AUDIT.md**  
  Full audit completed (see `FEATURES-AUDIT.md`). Confirmed gaps: broken `REVIEW-CONVENTIONS.instructions.md` reference in two locations, stale "90% confidence" description for `general-agent-behavior` in two locations, missing feature-overview for `update-validated-joists-test-data`, missing entry-point docs for `/fork-and-improve` in `lessons-learned-system.md`, and stale Phase 7 node in the planning pipeline quick reference.

- [ ] **#5 — Add a routing entry point for new users**  
  No "What do I use for X?" entry point exists. A user unfamiliar with the system must read `FEATURES.md` and self-identify the right pipeline. A lightweight `/start` prompt or router agent that asks what the user is trying to accomplish and routes them to the right tool would reduce friction.

- [ ] **#6 — Periodic hook coverage audit**  
  Only two hooks exist. The escalation path says passive guidance that fails 3x should become a hook, but there's no mechanism to detect when existing lessons have silently crossed that threshold. The `/review-lessons` prompt from #2 should also surface hook candidates.
