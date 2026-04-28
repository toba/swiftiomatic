---
# k3l-rnd
title: NoSelfReference strips 'self.' before keyword-named methods like 'is(_:)' producing invalid code
status: completed
type: bug
priority: high
created_at: 2026-04-27T20:59:50Z
updated_at: 2026-04-27T21:11:18Z
sync:
    github:
        issue_number: "475"
        synced_at: "2026-04-28T02:39:59Z"
---

## Problem

In `Sources/SwiftiomaticKit/Rules/Idioms/PreferLastWhere.swift`, the `isFilterArgumentSkipped` extension uses:

```swift
extension ExprSyntax {
    fileprivate var isFilterArgumentSkipped: Bool {
        if self.is(StringLiteralExprSyntax.self) { return true }
        if let call = self.as(FunctionCallExprSyntax.self),
            call.calledExpression.as(DeclReferenceExprSyntax.self)?.baseName.text == "NSPredicate"
        {
            return true
        }
        return false
    }
}
```

Removing the explicit `self.` (as the no-self-reference rule wants to) yields:

```swift
if is(StringLiteralExprSyntax.self) { return true }
```

…which is invalid Swift — `is` is a keyword and can't appear as a bare identifier at statement position. Same risk for `as(_:)` (`as` is also a keyword) on the next line, although in that one the receiver chain (`self.as(...)`) is followed by `?`/`.` so it's less obvious.

## Repro

Run the formatter (or whichever rule removes redundant `self.`) over the snippet above and observe the produced file fails to compile.

## Expected

The rule must skip stripping `self.` when the method/property name is a Swift keyword (`is`, `as`, `try`, `throw`, `init`, etc.) — these require `self.` (or backticks) to disambiguate from the keyword.

## Fix sketch

In the `self.` removal rule, before rewriting `self.foo(...)` → `foo(...)`, check whether `foo` is a reserved keyword identifier. If so, leave `self.` in place (or wrap in backticks, but skipping is safer).

## Files

- `Sources/SwiftiomaticKit/Rules/Idioms/PreferLastWhere.swift` (current victim — uses `self.is` / `self.as`)
- The no-self-reference rule (likely under `Sources/SwiftiomaticKit/Rules/`) — needs the keyword guard.



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantBackticks.swift`: promoted `swiftKeywords` from `private static` to module-internal `static` so other rules can reuse the canonical keyword list.
- `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantSelf.swift`: added a guard in `visit(_: MemberAccessExprSyntax)` that skips the strip when the member name is in `RedundantBackticks.swiftKeywords` (covers `is`, `as`, `try`, `throw`, etc.). The existing `init` guard is retained for clarity.
- `Tests/SwiftiomaticTests/Rules/Redundant/RedundantSelfTests.swift`: added `keepSelfBeforeIs`, `keepSelfBeforeAs`, and `keepSelfBeforeTry` to lock in the new behavior.

Verified with `swift_package_test --filter RedundantSelfTests`: 51 passed, 0 failed.
