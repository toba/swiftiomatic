---
# 752-2vn
title: CollapseSingleLineGetter drops 'mutating' from 'mutating get', breaking compilation
status: completed
type: bug
priority: high
created_at: 2026-08-02T17:40:16Z
updated_at: 2026-08-02T17:43:09Z
sync:
    github:
        issue_number: "760"
        synced_at: "2026-08-02T17:49:08Z"
---

## Summary

`CollapseSingleLineGetter` incorrectly collapses a `mutating get` accessor block into an implicit getter, silently dropping the `mutating` keyword. The reformatted code no longer compiles.

## Reproduction

Input:

```swift
var isAtEnd: Bool {
    mutating get {
        skipSpaces()
        return index >= scalars.count
    }
}
```

Formatted output (wrong):

```swift
var isAtEnd: Bool {
    skipSpaces()          // error: Cannot use mutating member on immutable value: 'self' is immutable
    return index >= scalars.count
}
```

`mutating` is lost, so the getter is treated as non-mutating and the `skipSpaces()` call fails to compile.

## Root cause

`Sources/SwiftiomaticKit/Rules/Declarations/CollapseSingleLineGetter.swift`

The transform guard (lines ~29-37) only permits collapsing when the accessor has no attributes and no effect specifiers:

```swift
acc.accessorSpecifier.tokenKind == .keyword(.get),
acc.attributes.isEmpty,
// TODO: restore acc.modifiers.isEmpty when swift-syntax adds modifiers to AccessorDeclSyntax (604.0.0+)
acc.effectSpecifiers == nil else { return node }
```

The `mutating` in `mutating get` is an **accessor modifier**, not an effect specifier, so none of the existing guard conditions reject it. The TODO comment claims modifier support only arrives in swift-syntax 604, but that is incorrect: the pinned **swift-syntax 603.0.1** already exposes `AccessorDeclSyntax.modifier` (singular, `DeclModifierSyntax?`). Verified in `.build/checkouts/swift-syntax/.../SyntaxNodesAB.swift` — the `AccessorDeclSyntax` layout has `attributes`, `modifier`, `accessorSpecifier`, `parameters`, `effectSpecifiers`, `body`.

## Fix

Add `acc.modifier == nil` to the guard (and remove/replace the stale TODO). This blocks collapsing for `mutating get`, `nonmutating get`, `borrowing get`, `consuming get`, etc. — any accessor carrying a modifier keeps its explicit `get` block.

## Tasks

- [x] Add a failing test: `mutating get { ... }` must be left untouched by CollapseSingleLineGetter (and the same for a single-statement `mutating get`).
- [x] Add `acc.modifier == nil` to the guard in CollapseSingleLineGetter.swift; drop the stale 604 TODO comment.
- [x] Confirm plain read-only `get { ... }` still collapses (no regression).
- [x] Run the filtered CollapseSingleLineGetter test suite, then the full suite once at the end.

## Summary of Changes

**Rule:** `Sources/SwiftiomaticKit/Rules/Declarations/CollapseSingleLineGetter.swift` — added `acc.modifier == nil` to the collapse guard and replaced the stale 604 TODO with an explanatory comment. Any modified accessor (`mutating`/`nonmutating`/`borrowing`/`consuming get`) now keeps its explicit `get` block.

**Tests:** `Tests/SwiftiomaticTests/Rules/CollapseSingleLineGetterTests.swift` — added `getterWithModifierShouldBePreserved` (multi- and single-statement `mutating get`) and restored the previously commented-out inline `var j { mutating get { return 0 } }` case in `multiLinePropertyGetter`.

**Verification:** filtered suite 7/7 pass; full suite 3503/3503 pass, no regressions.
