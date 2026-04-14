---
name: create-plan
description: Generate a comprehensive implementation plan as a markdown file for a feature or task
agent: InitialPlanner
argument-hint: Describe the feature or task to plan
tools: ['edit/createFile', 'search', 'search/usages', 'web/fetch', 'todo']
---
# Implementation Planning Request

I need a markdown file with a comprehensive implementation plan for the following task:

${input:task}

Please follow your 4-step process:
1. First, analyze this prompt carefully
2. Next, investigate the relevant code areas to understand the context better
3. Then ask me any clarifying questions you have. **WAIT TO CONTINUE UNTIL ANSWERS ARE PROVIDED**
4. Only after completing steps 1-3, create the markdown file with the implementation plan

Remember to explicitly state which step you're working on as you progress through your workflow.