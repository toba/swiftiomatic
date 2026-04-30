---
# fji-uwm
title: NoAwaitInsideWithLock
status: completed
type: feature
priority: normal
created_at: 2026-04-30T21:03:07Z
updated_at: 2026-04-30T21:07:47Z
parent: 7h4-72k
sync:
    github:
        issue_number: "581"
        synced_at: "2026-04-30T23:13:22Z"
---

Lint `Mutex.withLock` (and similar) bodies that contain an `await` — the lock is held across suspension which can block other waiters and risks deadlock.

## Decisions

- Group: `.unsafety`
- Default: `.warn`
- Lint-only — the fix is a refactor.
- Trigger: a closure passed to `.withLock { ... }` (any receiver) whose body transitively contains an AwaitExpr.

## Plan

- [x] Failing test
- [x] Implement `NoAwaitInsideWithLock`
- [x] Verify test passes; regenerate schema



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Unsafety/NoAwaitInsideWithLock.swift` — LintSyntaxRule. Walks the closure body with an `AwaitCollector` that skips nested closures (Task, etc).
- 6/6 tests passing.
- Schema regenerated.
