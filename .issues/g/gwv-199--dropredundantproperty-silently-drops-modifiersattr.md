---
# gwv-199
title: DropRedundantProperty silently drops modifiers/attributes (@preconcurrency, nonisolated(unsafe))
status: completed
type: bug
priority: normal
created_at: 2026-07-06T17:24:03Z
updated_at: 2026-07-06T17:36:45Z
sync:
    github:
        issue_number: "749"
        synced_at: "2026-07-06T17:37:58Z"
---

Default-on format rule DropRedundantProperty inlines `let x = expr; return x` -> `return expr` but discards any modifiers/attributes on the variable decl, silently losing semantics.

Repro (verified with sm 3.14.11):
```swift
func foo() -> Foo {
    @preconcurrency let foo = makeFoo()
    return foo
}
// sm format -> return makeFoo()   // @preconcurrency lost
```
Same for `nonisolated(unsafe) let target = ...`.

Root cause: Sources/SwiftiomaticKit/Rules/Redundancies/DropRedundantProperty.swift tryMerge guard (~lines 53-59) checks bindingSpecifier == .let, single binding, no type annotation, but never inspects varDecl.modifiers or varDecl.attributes.

Fix: add `varDecl.modifiers.isEmpty` and `varDecl.attributes.isEmpty` to the guard (mirrors upstream nicklockwood/SwiftFormat redundantVariable fix #2569, commit 6c59620).

Ported from: nicklockwood/SwiftFormat #2569.

- [ ] Add regression tests for @preconcurrency and nonisolated(unsafe) cases (confirm they fail first)
- [ ] Add modifiers.isEmpty / attributes.isEmpty guard
- [ ] Confirm tests pass, full suite green

## Summary of Changes

Added `varDecl.modifiers.isEmpty` and `varDecl.attributes.isEmpty` to the tryMerge guard in DropRedundantProperty.swift, so a `let` carrying modifiers/attributes (`@preconcurrency`, `nonisolated(unsafe)`, etc.) is no longer inlined into the return (which silently dropped them).

- [x] Regression tests `attributedLetNotFlagged` / `modifiedLetNotFlagged` (DropRedundantPropertyTests)
- [x] Guard added
- [x] Full suite green (3476 passed)

Ported from nicklockwood/SwiftFormat #2569 (commit 6c59620).
