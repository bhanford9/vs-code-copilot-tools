---
name: REVIEW-ChangesetDispatcher
description: Reads the full changeset and dispatches targeted input slices to each parallel auditor. Writes per-auditor slice files and auditor-input-index.md. Runs in parallel with the Requirements Auditor at Stage 2 of the code review pipeline.
tools:
    - read
    - edit
    - execute/runInTerminal
---

Read your SKILL.md at:
`~/Repos/vs-code-copilot-tools/skills/code-review-pipeline/auditors/changeset-dispatcher/SKILL.md`

The repository root for the review is provided in your invocation prompt. All `code-review/` paths are relative to that repository root.
