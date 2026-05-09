---
# v70-nog
title: Implement NoAnyViewInForEach rule
status: completed
type: feature
priority: normal
created_at: 2026-05-09T16:38:37Z
updated_at: 2026-05-09T16:40:53Z
parent: z75-gax
sync:
    github:
        issue_number: "682"
        synced_at: "2026-05-09T17:07:18Z"
---

Item 3 from z75-gax. Flag `AnyView(...)` constructed inside a `ForEach` body — type-erasure inside list rendering signals a missing `@ViewBuilder` or `Group` and triggers extra invalidation.

- [x] Write tests
- [x] Implement rule
- [x] Verify build/test passes



## Summary of Changes

- Added `Sources/SwiftiomaticKit/Rules/Swiftui/NoAnyViewInForEach.swift` — flag-only lint rule. Visits each `AnyView(...)` call and walks ancestors for the nearest `ForEach` call; flags when the AnyView's source position falls inside the ForEach's trailing closure (or any additional trailing closure), so receiver/`id:` arguments are excluded but nested closures (e.g. `Button { AnyView(...) }`) are still caught.
- Added `Tests/SwiftiomaticTests/Rules/NoAnyViewInForEachTests.swift` — 7 tests covering direct, branched, nested-closure, nested-ForEach (inner only) flagging plus negative cases.
- Full test suite: 3317 passed, 0 failed.
