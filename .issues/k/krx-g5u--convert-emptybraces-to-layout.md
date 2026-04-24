---
# krx-g5u
title: Convert EmptyBraces to layout
status: completed
type: task
priority: normal
created_at: 2026-04-24T22:58:41Z
updated_at: 2026-04-24T23:20:35Z
parent: os4-95x
sync:
    github:
        issue_number: "389"
        synced_at: "2026-04-24T23:31:21Z"
---

Move empty-brace collapsing from SyntaxFormatRule to the pretty-printer.

- [x] Add `ignoresDiscretionary` breaks around empty braces in `arrangeBracesAndContents`
- [x] Remove `Sources/SwiftiomaticKit/Syntax/Rules/EmptyBraces.swift`
- [x] Regenerate pipelines
- [x] Tests pass (2529 pass, 3 unrelated failures from concurrent NestedCallLayout edit)
