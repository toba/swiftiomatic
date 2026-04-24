---
# owc-wpj
title: BlankLinesBeforeControlFlow crashes on empty code blocks
status: completed
type: bug
priority: normal
created_at: 2026-04-24T18:16:23Z
updated_at: 2026-04-24T18:18:19Z
sync:
    github:
        issue_number: "370"
        synced_at: "2026-04-24T18:20:28Z"
---

## Problem
\`BlankLinesBeforeControlFlow.insertBlankLines\` crashes with \`Range requires lowerBound <= upperBound\` when visiting a \`CodeBlockSyntax\` with zero statements (e.g. \`func foo() {}\`).

Line 52: \`for i in 1..<visitedItems.count\` — when count is 0, this creates range \`1..<0\` which is invalid.

## Steps
- [x] Reproduce crash
- [x] Add test for empty code block
- [ ] Fix range guard in \`insertBlankLines\`
- [ ] Verify fix
