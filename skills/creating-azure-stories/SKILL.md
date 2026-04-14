---
name: creating-azure-stories
description: Create Azure DevOps work items (stories) with required structure including title, description sections (Blocked By, Backing Content, Goal, Details), and acceptance criteria. Use when creating Azure DevOps stories, work items, user stories, when user mentions Azure boards, story templates, acceptance criteria, or asks to write or review work items.
---

# Creating Azure Stories

## Story Creation Workflow

Copy this checklist and track progress:

```
Azure Story Creation:
- [ ] Identify blocking dependencies
- [ ] Write backing content (why this work is needed)
- [ ] Define product-level goal (1-2 sentences)
- [ ] Specify technical details (where/what, no code)
- [ ] Create 3-7 high-level acceptance criteria
- [ ] Review against format requirements
- [ ] Append to LessonsLearned.md if new codebase patterns were discovered
```

## Required Story Structure

Every Azure DevOps story must include:

1. **Title**: 5-10 word summary
2. **Description** with four sections:
   - **Blocked By**: Dependencies or "None identified"
   - **Backing Content**: Context and justification
   - **Goal**: 1-2 sentence outcome-focused description
   - **Details**: Technical specifics (where/what the work is)
3. **Acceptance Criteria**: 3-7 testable business requirements

**Complete template**: See [TEMPLATE.md](TEMPLATE.md)  
**Detailed formatting**: See [FORMAT_RULES.md](FORMAT_RULES.md)  
**Good/bad examples**: See [EXAMPLES.md](EXAMPLES.md)

## Critical Rules

- **File paths**: Always plain text with backticks (e.g., `src/api/handler.ts`), NEVER markdown links
- **Goal section**: Outcome-focused, not implementation details
- **Details section**: No code snippets, no step-by-step procedures, focus on WHAT and WHERE
- **Acceptance criteria**: High-level business requirements, not implementation details or test cases

## Section Quick Reference

**Blocked By**
```markdown
## Blocked By
Story #12345: Database migration
```
Or `None identified` if no dependencies.

**Backing Content**  
Answers: What problem? Why needed? What context does team need?

**Goal**  
1-2 sentences describing product-level outcome.

**Details**  
Where in codebase, which components, architecture diagrams (mermaid OK), affected systems.

**Acceptance Criteria**  
Checkbox list of testable business requirements:
```markdown
- [ ] User can authenticate using SSO
- [ ] System processes payments within 3 seconds
```

## Feedback Loop

Before writing a story, read [LessonsLearned.md](LessonsLearned.md) and apply any codebase-specific patterns from past sessions.

After completing, read `~/.copilot/skills/lessons-learned/SKILL.md` and follow the feedback loop process. LessonsLearned file: `~/.copilot/skills/creating-azure-stories/LessonsLearned.md`.
