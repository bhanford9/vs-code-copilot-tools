# Always-On Instructions

Instruction files that inject behavior into every relevant chat session automatically — no invocation required. The agent receives the rules as part of its context whenever the file scope matches.

## The Mechanism

VS Code Copilot instructions files use an `applyTo` glob in their frontmatter to determine when they activate. Files matching `**` apply to every session. Files matching a narrower glob apply only when files matching that pattern are in context.

This makes instructions files the right tool for rules that should be ambient — things the agent should always do or always know, not things the user has to remember to ask for.

## The Two Always-On Files

### General Agent Behavior (`applyTo: "**"`)

Applies to every chat session without exception. Contains a single rule: ask clarifying questions any time confidence is below 90%.

This addresses a common failure mode — the agent proceeding on ambiguous instructions and producing work that needs to be redone. The threshold creates a consistent expectation across all interactions regardless of topic or tool.

### REVIEW-CONVENTIONS (`applyTo: "**/code-review/*.md"`)

Applies automatically when working inside the `/code-review/` output directory — the directory where the code review pipeline writes its audit reports. Injects shared conventions that all review auditors must follow: severity levels, output format, and rules for writing actionable recommendations.

The narrow `applyTo` scope means these conventions are only present when actually working within a review context, not globally. This keeps sessions clean while ensuring any agent writing to that directory gets consistent formatting rules without needing to be explicitly told.

## Reference Files

| File | Role |
|------|------|
| [`instructions/general-agent-behavior.instructions.md`](../../instructions/general-agent-behavior.instructions.md) | 90% confidence clarifying question rule — applies everywhere |
| [`instructions/REVIEW-CONVENTIONS.instructions.md`](../../instructions/REVIEW-CONVENTIONS.instructions.md) | Code review output conventions — applies inside `/code-review/` |
