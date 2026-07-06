---
# trh-pfv
title: UseFirstWhere false positive on trailing-closure first { } (filter{}.first{})
status: completed
type: bug
priority: normal
created_at: 2026-07-06T17:24:30Z
updated_at: 2026-07-06T17:36:45Z
sync:
    github:
        issue_number: "748"
        synced_at: "2026-07-06T17:37:58Z"
---

Default-on lint rule UseFirstWhere flags `xs.filter { ... }.first { ... }` as 'prefer first(where:) over filter(_:).first', but the trailing-closure `.first { }` is already first(where:), not the .first property — false positive.

Repro (sm 3.14.11):
```swift
planets.filter { $0.hasMoons }.first { $0.isHabitable }   // wrongly flagged
planets.filter({ }).first(where: { $0.isHabitable })       // wrongly flagged
```

Root cause: Sources/SwiftiomaticKit/Rules/Collections/UseFirstWhere.swift (~lines 12-22) lacks the guard that UseMinMax.swift:17 already has: `node.parent?.is(FunctionCallExprSyntax.self) != true`. When .first is the callee of a function call (trailing/explicit closure), it must not be flagged.

Fix: add the FunctionCallExprSyntax parent guard to UseFirstWhere.visit(_:).

Surfaced by: nicklockwood/SwiftFormat preferFirstWhere tests (commit da112cf / #2561).

- [ ] Add regression test for filter{}.first{} and filter().first(where:) (confirm fails)
- [ ] Add FunctionCallExprSyntax parent guard
- [ ] Confirm green

## Summary of Changes

Added `node.parent?.is(FunctionCallExprSyntax.self) != true` guard to UseFirstWhere.visit(_:), mirroring UseMinMax.swift:17, so trailing-closure `filter{}.first{}` / `filter().first(where:)` (already the desired first(where:) form) is no longer flagged.

- [x] Regression cases added to UseFirstWhereTests.nonTriggering
- [x] Guard added
- [x] Full suite green (3476 passed)

Surfaced by nicklockwood/SwiftFormat preferFirstWhere tests (#2561).
