---
# nly-6uj
title: 'sm format rewrites ''if cond { return x }; return switch { ... }'' as ternary ''cond ? x : switch { ... }'' which doesn''t compile'
status: completed
type: bug
priority: high
created_at: 2026-05-08T22:08:46Z
updated_at: 2026-05-08T22:23:28Z
sync:
    github:
        issue_number: "671"
        synced_at: "2026-05-08T22:24:57Z"
---

## Summary

`sm format` rewrites a guarded `return switch` into a ternary expression where the `false` branch is a `switch` expression. Swift only allows `switch` as an expression in `return`, `throw`, or assignment positions — not as a sub-expression of `? :`. The rewrite is invalid.

## Example

`Integrations/CSL/Sources/Terms/Values/OrdinalValue.swift`:

Before (compiles):
```swift
func matches(_ number: Int) -> Bool {
    if numeric < 0 { return true } // happens if reverted to default .ordinal
    return switch match {
        case .wholeNumber: numeric == number
        case .lastTwoDigits: numeric == number.lastTwoDigits
        default: numeric == number.lastDigit
    }
}
```

After `sm format` (does not compile):
```swift
func matches(_ number: Int) -> Bool {
    numeric < 0
        ? true
        : switch match {
            case .wholeNumber: numeric == number
            case .lastTwoDigits: numeric == number.lastTwoDigits
            default: numeric == number.lastDigit
        }
}
```

Compiler error:
> 'switch' may only be used as expression in return, throw, or as the source of an assignment

## Suggested fix

The rewrite (presumably `useTernaryExpression` or similar) must check that all branches of the resulting ternary are valid sub-expressions. `switch` and `if` expressions are only valid in `return` / `throw` / assignment positions, so they cannot appear in either branch of a ternary.

## Severity

High. Produces uncompilable code from compilable input.



## Summary of Changes

`UseTernary` now refuses to fold an `if`/`else` (or `if cond { return x }` + bare `return …`) into a ternary when either branch's expression is a `switch` or `if` expression. Those forms are only valid in return/throw/assignment-RHS positions — they cannot appear as a sub-expression of a ternary `?:`, so the previous rewrite produced uncompilable `cond ? x : switch { … }`.

`Sources/SwiftiomaticKit/Rules/Conditions/UseTernary.swift`:
- Added `isStatementOnlyExpression(_:)` returning `true` for `SwitchExprSyntax` / `IfExprSyntax`.
- Gated the three rewrite paths (`tryConvert` return-pair, `tryConvert` assignment-pair, `tryConvertIfReturnPair`) on neither branch being statement-only.

`Tests/SwiftiomaticTests/Rules/UseTernaryTests.swift`: added `doesNotConvertWhenElseReturnsSwitchExpression`, `doesNotConvertWhenIfBranchReturnsIfExpression`, `doesNotConvertAssignmentWithSwitchExpression` (using the exact OrdinalValue.swift shape from the bug report and the assignment / if-expression analogs).

Full test suite: 3285 passed, 0 failed.
