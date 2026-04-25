---
# c01-o1f
title: 'Cat 8: Documentation & Comments (3 rules)'
status: completed
type: feature
priority: normal
created_at: 2026-04-15T00:27:58Z
updated_at: 2026-04-25T23:48:43Z
parent: qlt-10c
sync:
    github:
        issue_number: "317"
        synced_at: "2026-04-25T23:53:21Z"
---

| SwiftLint Rule | Swiftiomatic Name | Scope | Description |
|---|---|---|---|
| `orphaned_doc_comment` | OrphanedDocComment | `.lint` | `///` comment not attached to any declaration |
| `local_doc_comment` | NoLocalDocComments | `.lint` | `///` inside function bodies should be `//` |
| `expiring_todo` | ExpiringTodo | `.lint` | TODO/FIXME with dates should be resolved by that date |



## Summary of Changes

- Added `OrphanedDocComment` lint rule (`Sources/SwiftiomaticKit/Rules/Comments/OrphanedDocComment.swift`) — flags `///` doc comments followed by a regular comment instead of a declaration; ports SwiftLint's `orphaned_doc_comment` logic, including the `////`/`/***` file-header carve-outs.
- Added `NoLocalDocComments` lint rule (`Sources/SwiftiomaticKit/Rules/Comments/NoLocalDocComments.swift`) — flags `///` doc comments inside function/init/deinit/accessor bodies, exempting nested `func` declarations (which can legitimately carry doc comments).
- Added `ExpiringTodo` lint rule (`Sources/SwiftiomaticKit/Rules/Comments/ExpiringTodo.swift`) with a custom `ExpiringTodoConfiguration` (date format, delimiters, separator, approaching-expiry threshold, and per-level severities); emits findings at the exact column of the bracketed date.
- Tests: `OrphanedDocCommentTests`, `NoLocalDocCommentsTests`, `ExpiringTodoTests` (17 cases total) — all passing along with the full 2914-test suite.
- Regenerated `Pipelines+Generated.swift` and `ConfigurationRegistry+Generated.swift`.
- Configuration entries for the three rules need to be added under `comments` in the project configuration (agent is hook-blocked from editing it).
