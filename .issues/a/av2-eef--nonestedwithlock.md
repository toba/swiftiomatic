---
# av2-eef
title: NoNestedWithLock
status: completed
type: feature
priority: normal
created_at: 2026-04-30T21:07:56Z
updated_at: 2026-04-30T21:12:53Z
parent: 7h4-72k
sync:
    github:
        issue_number: "583"
        synced_at: "2026-04-30T23:13:22Z"
---

Lint nested `<receiver>.withLock { ... <receiver>.withLock { ... } ... }` on the same receiver — guaranteed deadlock with non-recursive locks (`Mutex`).

## Decisions

- Group: `.unsafety`
- Default: `.warn`
- Lint-only.
- Trigger: a `withLock` call inside the closure body of another `withLock` call where the receiver expressions are textually identical.

## Plan

- [x] Failing test
- [x] Implement `NoNestedWithLock`
- [x] Verify test passes; regenerate schema



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Unsafety/NoNestedWithLock.swift` — receiver match by `trimmedDescription`. Walks the outer closure body with a collector.
- 5/5 tests passing.
- Schema regenerated.
