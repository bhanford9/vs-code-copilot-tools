# LessonsLearned.GLOBAL.md — create-knowledge-docs

Process and workflow observations applicable across any use of this skill.
Only add entries when something was hard, slow, surprising, or went wrong.
Do not document sessions that went smoothly.

---

## Generic Skills Must Use Fully Synthetic Examples

Category: Process/Model

The first version of this skill contained domain-specific examples drawn from the project that was active during authoring (domain terms, system names, file paths). These had to be scrubbed in a follow-up session after the user flagged them as a data protection violation.

- DO use completely invented, generic examples: payment gateways, schedulers, auth flows, queue systems.
- DON'T use domain terms, system names, or concepts from any real project — even "theoretical" examples that happen to mirror a real system are a violation.
- When in doubt, ask: could a reader identify the project from this example? If yes, replace it.

---

## Mermaid Node Labels Require `<br/>` Not `\n` for Line Breaks

Category: Process/Model

All Mermaid node labels generated during the initial documentation session used `\n` for line breaks (e.g., `["Design Engine\n(chooses geometry)"]`). These rendered as the literal characters `\n` instead of a line break in every renderer tested.

- DO use `<br/>` inside Mermaid node label strings for line breaks.
- DON'T use `\n` — it is not interpreted as a newline by Mermaid.
- Applies to all node types: rectangular `[]`, round `()`, diamond `{}`, cylinder `[()]`, etc.

---

## Mermaid Subgraph Arrows Should Target the Subgraph ID, Not Internal Nodes

Category: Process/Model

When a container node (e.g., a shared data model) was expanded into a `subgraph` with internal nodes, the arrows were rerouted to connect to those internal nodes. This scattered edge labels throughout the diagram interior and made the layout unreadable.

- DO connect external arrows to the `subgraph` ID — they attach cleanly to the outer boundary.
- DON'T route arrows to internal nodes inside a subgraph unless the diagram's explicit purpose is to show which internal part is accessed.
- Internal nodes inside a subgraph should be a visual listing only — no edges of their own unless essential.

---

## Knowledge Base Directory Structure Needs an Explicit Convention for Section Folders

Category: Process/Model

The initial skill specification described a flat numbered file scheme (`03.1-topic.md`, `03.2-topic.md`). When the user asked for directory cleanliness, the flat scheme was replaced with a proper hierarchy — but this required a retrofit conversation rather than being designed in from the start.

- DO specify a directory-based hierarchy from the outset: each section is either a leaf file or a folder containing `00-overview.md` plus numbered children.
- DON'T use dot-notation flat filenames (e.g., `03.1-topic.md`) — they don't scale and obscure the real structure.
- The section overview file inside a folder must be named `00-overview.md`, not `README.md`. `README.md` is reserved for the single knowledge base root navigation index. Using `README.md` inside section folders causes ambiguity for agents doing `file_search` and loses the numbering signal.
- `00` is reserved — never use it for a content sub-section.

---

## Migration Steps Belong in the Skill, Not Just Discovered at Migration Time

Category: Process/Model

The migration procedure (flat file → section folder) was written into the knowledge base README rather than being part of the skill itself. Future uses of this skill should have the migration steps available without needing to find the project-specific README.

- The skill should include the 5-step migration procedure as a standard section:
  1. Create folder
  2. Move flat file to `00-overview.md`
  3. Add sub-section files
  4. Update cross-references
  5. Update the root README's Reading Order table
