---
# ho3-x1j
title: 'Lint rule: file/line params → sourceLocation pattern'
status: completed
type: task
priority: normal
created_at: 2026-04-12T23:15:48Z
updated_at: 2026-04-12T23:18:33Z
parent: ogh-b3l
sync:
    github:
        issue_number: "238"
        synced_at: "2026-04-12T23:20:54Z"
---

Detect `file: StaticString = #filePath, line: UInt = #line` parameter pattern in test helpers and suggest `sourceLocation: SourceLocation = #_sourceLocation`. Lint scope, correctable. Deferred from 20b-1vw.



## Summary of Changes

Created `PreferSourceLocationRule` (lint, correctable). Detects `file: StaticString = #filePath, line: UInt = #line` parameter pairs and auto-corrects to `sourceLocation: SourceLocation = #_sourceLocation`.
