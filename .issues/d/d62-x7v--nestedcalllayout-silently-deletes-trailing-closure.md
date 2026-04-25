---
# d62-x7v
title: NestedCallLayout silently deletes trailing-closure bodies when collapsing
status: completed
type: bug
priority: critical
created_at: 2026-04-25T20:05:50Z
updated_at: 2026-04-25T20:28:29Z
sync:
    github:
        issue_number: "413"
        synced_at: "2026-04-25T22:35:07Z"
---

## Severity: critical — silent code deletion

`NestedCallLayout` rebuilds nested function calls by stringifying `call.arguments` only. `FunctionCallExprSyntax.trailingClosure` and `additionalTrailingClosures` are NOT included in the rebuild, so any call with a trailing closure gets its closure body deleted when the rule collapses it.

## Reproduction

`Sources/SwiftiomaticKit/Rules/Idioms/PreferStaticOverClassFunc.swift` (or any file) when the project's `swiftiomatic.json` enables `nestedCallLayout: inline`:

```swift
// Before
result.memberBlock.members = MemberBlockItemListSyntax(
    result.memberBlock.members.map { member in
        guard let classModifier = classModifier(in: member.decl) else { return member }
        ...
    })

// After `sm format`
result.memberBlock.members = MemberBlockItemListSyntax(result.memberBlock.members.map())
```

The entire `{ member in ... }` trailing closure body is gone — replaced by empty parens.

## Root cause

`Sources/SwiftiomaticKit/Rules/Wrap/NestedCallLayout.swift`:
- `inlineArgText` (line 193): `call.arguments.map(\.trimmedDescription).joined(separator: ", ")`
- `buildWrappedArgs` (line 242): same pattern
- `buildFullyInlineText`, `buildInnerInlineText`, etc.: all use `calledExpression.trimmedDescription + "(" + inlineArgText + ")"`

None of the rebuild paths include `call.trailingClosure` or `call.additionalTrailingClosures`. When the outer call wraps an inner call with a trailing closure (`Outer(inner.map { ... })`), the rebuild produces `Outer(inner.map())`.

## Fix

`soleArgumentCall(_:)` should bail when either the outer or inner call carries a trailing closure. Trailing-closure-bearing calls are not safely rebuildable by the current code paths.

Long-term: rebuild logic should preserve trailing closures, but that's out of scope for the urgent fix.

## Why existing tests missed this

`NestedCallLayoutTests.swift` covers nested calls of the form `Outer(Inner(args))` and chains, but not `Outer(receiver.method { closure })`. The newly-completed `enu-4zl` fix added more tests but none for trailing closures. Adding regression tests is part of this fix.

## Related

- Discovered while investigating `6rg-85v` (PreferStaticOverClassFunc + UseImplicitInit on the rule's own source)
- Likely root cause of the `.drop()` example user reported in EmptyExtensions.swift

## TODO

- [x] Add failing test: nested call wrapping a trailing-closure call
- [x] Add failing test: outer call with its own trailing closure
- [x] Bail `soleArgumentCall` when inner or outer has trailing closure
- [x] Verify `PreferStaticOverClassFunc.swift` formats without dropping closures
- [x] Verify `EmptyExtensions.swift` formats without dropping closures


## Summary of Changes

`Sources/SwiftiomaticKit/Rules/Wrap/NestedCallLayout.swift`:
- `soleArgumentCall(_:)` now bails when either the outer or inner call carries a trailing closure or additional trailing closures. The rebuild paths only stringify `arguments`, so a naive rebuild would silently delete the closure body.
- DocC updated.

`Tests/SwiftiomaticTests/Rules/Wrap/NestedCallLayoutTests.swift`:
- `innerCallWithTrailingClosureNotCollapsed` — exact regression case (`MemberBlockItemListSyntax(items.map { ... })`).
- `outerCallWithTrailingClosureNotCollapsed` — outer call with its own trailing closure.

## Verification

- 2748 tests passed (full suite)
- `sm format` on `PreferStaticOverClassFunc.swift` and `EmptyExtensions.swift` no longer drops `.map`/`.drop` trailing closure bodies
