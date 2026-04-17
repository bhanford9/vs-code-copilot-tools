# LessonsLearned.GLOBAL.md — paper-banana-infographics

Process and workflow observations applicable across any use of this skill.
Only add entries when something was hard, slow, surprising, or went wrong.
Do not document sessions that went smoothly.

---

### Always Specify Aspect Ratio in the Prompt
Category: Process/Model

Paper Banana accepts an aspect ratio parameter (e.g., 3:2, 4:3, 16:9, 21:9). Always include it in the final prompt — omitting it causes Paper Banana to pick a default that may not suit the content layout.
- For left-to-right or circular flow diagrams: `3:2` (landscape)
- For top-down or vertical layered diagrams: `3:4` or `4:5` (portrait)
- For wide comparison/timeline layouts: `21:9`
- For tall narrow formats: `2:3` or `1:4`
Add an `Aspect Ratio` row to the Metadata table and a corresponding `**Aspect ratio:**` line in the prompt text.

---

### Protect Verbatim Text with an Explicit Guard
Category: Process/Model

Paper Banana will paraphrase, reword, or misspell any text it isn't told to treat as literal. For titles, taglines, or any string that must appear exactly as written, add an explicit instruction: "Use this exact text, spelled exactly as written." Do not assume quoted text will be preserved.

---

### Markdown Formatting Has No Visual Effect
Category: Process/Model

Bold, italic, and other markdown emphasis in the prompt does not produce visual styling in the output. To achieve visual emphasis (color, weight, size), describe the desired treatment explicitly in the Visual Style section — e.g., "render this phrase in a vivid accent color that differs visibly from surrounding text."

---

### Enumerate Every Arrow Explicitly
Category: Process/Model

Without a complete arrow list, Paper Banana invents extra connections and points arrows in unexpected directions. Always provide: (1) an exhaustive numbered list of every arrow with source → destination, (2) a total arrow count, and (3) a rule that no unlisted arrows may be added. This eliminates ambiguity about what connects to what.

---

### Parallel Branch Nodes Generate Unreliable Geometry
Category: Process/Model

Representing parallel destinations as separate flow nodes with a merge point consistently produces mangled or extra arrows. When two items are attributes or sub-types of the same concept, nest them as visual sub-elements inside a single parent node instead of as independent nodes with their own arrows. This simplifies the arrow count and produces cleaner output.

---

### Separate Agent Instructions from Image Text
Category: Process/Model

Descriptive text written to guide the agent (position hints, layout constraints, node descriptions) often leaks into the rendered image as literal text. Add an explicit rule: "Do not render layout instructions or node descriptions as image text." Keep the prompt text's instructional layer cleanly separated from what should actually appear in the image.

---

### Anchor Color Descriptions with Specifics
Category: Process/Model

Vague color terms ("dark," "light," "muted") produce unpredictable results. Anchor background and palette choices with hex values or concrete comparisons (e.g., "#1e1e2e — rich dark gray, not pure black"). This is especially important for background darkness, which Paper Banana tends to interpret at extremes.

---

### Repeated Elements Require an Explicit One-Location Rule
Category: Process/Model

Paper Banana tends to restate the same concept in multiple places — once in the flow and again in a legend, caption, or callout. A general instruction to "avoid repetition" is insufficient. Add a strict rule: "No element, label, or description may appear more than once in the entire image. Each piece of text exists in exactly one place."

---

### Parallel Sub-Agents for Batch Prompt Generation Are Reliable When Fully Self-Contained
Category: Process/Model

When generating multiple Paper Banana prompts in one session, running them as parallel sub-agents is effective — but only if each sub-agent receives the full skill instructions inline (not just a reference to the skill file). A sub-agent given only a file path will not reliably read it. Embed the condensed skill instructions, all critical lessons, the concept details, and the source content directly in the sub-agent prompt. All 7 prompts generated in one batch with no failures when this pattern was followed.

---

### 4-Column Layouts Require Landscape Orientation
Category: Process/Model

Portrait (3:4) is too narrow for 4 side-by-side columns — nodes become cramped and labels truncate. Switch to landscape (4:3) whenever the layout has 4 or more vertical columns. This was discovered when designing the "Actors, Controller, Coordination & Learning" diagram (Diagram 6): a 4:3 landscape switch resolved the spacing problem before generating the prompt.
