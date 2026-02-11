---
trigger: always_on
---

# Comments & Documentation

Write comments that explain *why* code exists, not *what* it does. Document tricky logic and mark incomplete work with `// TODO:` items.

Use Xcode documentation comments (`///` for single-line, `/** */` for multi-line) with DocC markdown formatting:

- `#` for headers, `*italics*` / `**bold**` for emphasis
- `*` or `-` for bullet points, `1.` for numbered lists
- Backticks for inline `code`, fenced blocks (` ``` `) for multi-line code

For functions, use these DocC callouts:

- `- Parameter <name>:` — describe each parameter
- `- Returns:` — describe the return value
- `- Throws:` — describe possible errors
- `- Important:` or `- Warning:` — highlight critical info
- `- Precondition:` / `- Postcondition:` — specify required conditions before/after execution