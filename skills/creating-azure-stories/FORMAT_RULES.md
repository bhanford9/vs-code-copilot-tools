# Azure Story Format Rules

Detailed formatting requirements for each section of Azure DevOps stories.

## Story Number
- Automatically assigned by Azure DevOps (e.g., 12345)
- Referenced as "Story #12345" when linking

## Title
- 5-10 words
- Clearly conveys what is being done
- Example: "Add OAuth Authentication to API Gateway"

## Description Sections

### Blocked By

Lists dependencies that must complete before this story can start.

**Format:**
```markdown
## Blocked By
[work item references or "None identified"]
```

**Valid examples:**
- `Story #12345: Database schema migration`
- `Story #12346, Story #12347`
- `External dependency: API vendor approval`
- `None identified`

### Backing Content

Background and context explaining why work is needed.

**Should answer:**
- What problem does this solve?
- What is the business justification?
- What context does the team need?

**Format:**
```markdown
## Backing Content
[concise background and context]
```

**Keep it concise** but provide necessary context for team understanding.

### Goal

Product-level outcome description.

**Requirements:**
- 1-2 sentences maximum
- Outcome-focused, not implementation
- Written from product/user perspective
- No technical implementation details

**Format:**
```markdown
## Goal
[1-2 sentence outcome description]
```

**Good examples:**
- "Enable users to reset passwords without contacting support"
- "Reduce API response time to under 200ms for improved user experience"

**Bad examples:**
- "Implement caching layer using Redis" (implementation detail)
- "Refactor authentication service" (not outcome-focused)

### Details

Technical and project specifics.

**Should include:**
- Where in codebase work occurs (file paths as plain text)
- Which components/features affected
- Architecture/design diagrams (mermaid supported)
- Integration points or affected systems

**Must NOT include:**
- Code snippets
- Step-by-step implementation procedures
- HOW to implement (only WHAT and WHERE)

**Format:**
```markdown
## Details
[technical specifics without implementation details]
```

**File path rules:**
- Use backticks: `src/components/Header.tsx`
- NEVER use markdown links: ~~`[Header](src/components/Header.tsx)`~~
- Content gets copied to Azure DevOps where links don't work

## Acceptance Criteria

High-level testable business requirements.

**Requirements:**
- 3-7 criteria per story
- High-level and business-focused
- Testable and verifiable
- Observable behaviors or outcomes
- NOT minor implementation details
- NOT exhaustive test cases

**Format:**
```markdown
## Acceptance Criteria
- [ ] [Testable requirement 1]
- [ ] [Testable requirement 2]
```

**Good examples:**
- ✓ User can successfully authenticate using SSO
- ✓ System processes payments within 3 seconds
- ✓ Dashboard displays real-time data with no more than 5-second lag
- ✓ Error messages are displayed in user's selected language

**Bad examples:**
- ✗ Code must have proper error handling (too vague, implementation)
- ✗ All buttons must be 32px height (too specific, minor detail)
- ✗ Function must return HTTP 200 status (implementation detail)
- ✗ Unit tests pass (not a business requirement)

## Markdown Guidelines

- Description section headers: `##` (H2 only — do not use `###`)
- Acceptance criteria: checkbox format `- [ ]`
- Code/file references: backticks only, no links
- Work item references: "Story #[NUMBER]"
