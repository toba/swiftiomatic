---
# tw2-lv2
title: 'RedundantReturn: support multi-branch implicit returns'
status: completed
type: feature
priority: normal
created_at: 2026-04-23T15:46:11Z
updated_at: 2026-04-23T16:06:57Z
sync:
    github:
        issue_number: "358"
        synced_at: "2026-04-23T16:14:37Z"
---

## Context

`RedundantReturn` currently only removes `return` from **single-expression** bodies (one `ReturnStmtSyntax` as the sole `CodeBlockItem`). But Swift also allows implicit returns when **every branch** of a control flow statement returns, e.g.:

```swift
var hasAnyComments: Bool {
    contains {
        switch $0 {
        case .lineComment, .docLineComment, .blockComment, .docBlockComment:
            return true
        default:
            return false
        }
    }
}
```

Here the closure body is a single `switch` expression where every case returns — `return` can be omitted from all branches.

## Scope

Extend `RedundantReturn` to strip `return` when the body is a single control-flow statement and all terminal branches are `return` statements:

- [x] `switch` — every `case`/`default` ends with `return <expr>`
- [x] `if`/`else if`/`else` — every branch ends with `return <expr>` (must have `else`)
- [x] Nested: branches containing another exhaustive control-flow (switch-in-if, if-in-switch, etc.)
- [x] Closures, computed properties, functions, subscripts (all existing `visit` entry points)
- [x] Add tests for each pattern
- [x] Ensure single-expression behavior is unchanged (no regressions)

## Non-goals

- `guard` statements (these don't form exhaustive branches)
- `do`/`catch` (uncommon as return-only bodies)
- Ternary expressions (already single-expression, already handled)

## References

- Current rule: `Sources/SwiftiomaticKit/Syntax/Rules/Redundant/RedundantReturn.swift`
- Swift Evolution: [SE-0255](https://github.com/apple/swift-evolution/blob/main/proposals/0255-omit-return.md) (implicit returns from single expressions)
- Swift 5.9 extended this to `if`/`switch` expressions


## Summary of Changes

Extended `RedundantReturn` to handle exhaustive `if`/`switch` expressions per [SE-0380](https://github.com/swiftlang/swift-evolution/blob/main/proposals/0380-if-switch-expressions.md) (Swift 5.9).

**Rule changes** (`RedundantReturn.swift`):
- Added `containsExhaustiveReturn` — detects single if/switch with all-return branches
- Added `allBranchesReturn`, `allCasesReturn`, `branchReturns` — recursive branch analysis
- Added `stripReturnsFromIf`, `stripReturnsFromSwitch`, `stripBranch` — recursive return removal
- Added `expressionFromItem` — unwraps `ExpressionStmtSyntax` for if/switch access
- Updated all four visit methods and `transformAccessorBlock` to fall back to multi-branch path
- Each branch must be a single expression (per SE-0380 requirements)

**Tests** (`OmitReturnsTests.swift`): 9 new tests covering switch in closure, switch in computed property, if/else in function, if/else-if/else chain, nested switch-in-if, switch in explicit getter, if-without-else (negative), non-return branch (negative), multi-statement branch (negative).
