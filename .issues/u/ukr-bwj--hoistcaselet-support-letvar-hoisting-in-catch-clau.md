---
# ukr-bwj
title: 'HoistCaseLet: support let/var hoisting in catch-clause patterns'
status: completed
type: feature
priority: normal
created_at: 2026-05-26T15:27:14Z
updated_at: 2026-05-26T15:30:57Z
sync:
    github:
        issue_number: "709"
        synced_at: "2026-05-26T15:33:26Z"
---

`HoistCaseLet` rewrites `let`/`var` placement in switch, if/guard/while-case, and for-case patterns, but does **not** handle `catch` clause patterns.

Observed (no change made):
```swift
do {} catch Pattern.error(let x, let y) { ... }   // stays as-is
```
Expected (outerPattern placement):
```swift
do {} catch let Pattern.error(x, y) { ... }
```

Upstream realm/SwiftLint extended `pattern_matching_keywords` (#6534, commit 6c55e0ea) to flag catch-clause patterns (and tuples/associated values within them). `HoistCaseLet` should add a `transform(_: CatchItemSyntax, ...)` (or equivalent) overload reusing `distributeLetVarThroughPattern` / `hoistLetVarFromPattern`.

## Tasks
- [x] Add test asserting catch-clause hoist/distribute for both placements
- [x] Add transform overload for catch-item patterns
- [x] Confirm tests pass (filtered HoistCaseLet suite green; full suite deferred to /commit)

Source: realm/SwiftLint pattern_matching_keywords #6534

## Summary of Changes

`HoistCaseLet` now normalizes `let`/`var` placement in `catch`-clause patterns, matching its existing coverage of switch / if-guard-while-case / for-case.

- Added `transform(_ node: CatchItemSyntax, ...)` to `HoistCaseLet.swift`, reusing `distributeLetVarThroughPattern` (eachBinding) and `hoistLetVarFromPattern` (outerPattern). Guards on the optional `CatchItemSyntax.pattern`.
- Added a `visit(_ node: CatchItemSyntax)` dispatch in `RewritePipeline.swift` (the hand-written `CompactSyntaxRewriter`).
- Added two tests to `HoistCaseLetTests`: `catchClause` (eachBinding) and `hoistCatchClause` (outerPattern).

Examples:
- eachBinding: `catch let Pattern.error(x, y)` → `catch Pattern.error(let x, let y)`
- outerPattern: `catch Pattern.error(let x, let y)` → `catch let Pattern.error(x, y)`

Filtered suite (`UseLetInEveryBoundCaseVariableTests`): 15 passed, 0 failed.
