---
name: CSharp Diagnostics
description: How to check C# files for errors and warnings in this codebase
applyTo: "**/*.cs"
---

# C# Error Checking

- ALWAYS use the **"Check Changed Files"** task for diagnostics — NEVER use the VS Code `get_errors` tool for C# files
- The task deletes `csharp-diagnostics-report.tmp` at start and creates it when complete — wait for it to exist before reading
- In multi-root workspaces, the tmp file is written to the root of the **opened workspace folder**, not the `.sln` directory — check the workspace root first if the file is not found
- Focus on **Error** and **Warning** severity items only; ignore **Info** severity suggestions
- Check after every C# file modification; re-run to verify fixes before marking work complete
- Do NOT run `dotnet build` or `msbuild` just to check errors
