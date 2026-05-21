---
# 74e-aaa
title: 'Mirror swift-format fix: double space in where-only catch clause'
status: completed
type: bug
priority: normal
created_at: 2026-05-21T16:32:14Z
updated_at: 2026-05-21T16:36:27Z
sync:
    github:
        issue_number: "692"
        synced_at: "2026-05-21T16:37:04Z"
---

Upstream swift-format commit b6808a10 (PR #1203, 2026-05-14) fixes a double-space bug between `catch` and `where` when a `catch` clause has no pattern, only a `where` clause.

Both CatchClauseSyntax and WhereClauseSyntax visitors were emitting whitespace before the `where` keyword. Upstream fix: suppress the catch-clause-level whitespace when the catch item has no pattern.

Touches Sources/SwiftFormat/PrettyPrint/TokenStreamCreator.swift upstream — mirror file in Swiftiomatic is Sources/SwiftiomaticKit/Layout/TokenStream*.swift.

## Tasks
- [x] Write a failing test for `do { ... } catch where cond { ... }` formatting
- [x] Check if Swiftiomatic exhibits the same double-space bug
- [x] If so, port the upstream fix
- [x] Confirm test passes; run filtered suite
- [x] Run full suite once before commit

Reference: ~/Developer/swiftiomatic-ref/swift-format commit b6808a10bf0e4f04c9e9eb082a9f9252fe35769f



## Summary of Changes

Ported upstream swift-format #1203 fix to `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+ControlFlow.swift` (`visitCatchClause`): skip the catch-item preceding break when the item has no pattern (bare `where` clause); the `WhereClauseSyntax` visitor emits its own break. Applies to both the single-item (`else` branch, now guarded by `pattern != nil`) and multi-item paths.

Added `catchWhereOnly_noBreakBeforeCatch` and `catchWhereOnly_breakBeforeCatch` in `Tests/SwiftiomaticTests/Layout/DoStmtTests.swift`. Both pass. Full suite: 3371 passed.
