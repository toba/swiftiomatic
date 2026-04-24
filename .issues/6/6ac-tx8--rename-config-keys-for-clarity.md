---
# 6ac-tx8
title: Rename config keys for clarity
status: completed
type: task
priority: normal
created_at: 2026-04-24T19:45:00Z
updated_at: 2026-04-24T19:48:01Z
sync:
    github:
        issue_number: "377"
        synced_at: "2026-04-24T20:43:40Z"
---

- [x] Rename `blankLines.beforeControlFlow` → `blankLines.beforeControlFlowBlocks`
- [x] Rename `lineBreaks.beforeControlFlowKeywords` → `lineBreaks.elseCatchOnNewLine`
- [x] Update all references in source, config, schema, tests, and issues


## Summary of Changes

Renamed config keys and Swift types:
- `blankLines.beforeControlFlow` → `blankLines.beforeControlFlowBlocks` (key only, type `BlankLinesBeforeControlFlow` unchanged)
- `lineBreaks.beforeControlFlowKeywords` → `lineBreaks.elseCatchOnNewLine` (key + type `BeforeControlFlowKeywords` → `ElseCatchOnNewLine`)
- File renamed: `BeforeControlFlowKeywords.swift` → `ElseCatchOnNewLine.swift`
- Updated all references in source, tests, config, and docs
- Generated files (schema, pipelines, registry) will regenerate on build
