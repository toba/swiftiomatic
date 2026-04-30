---
# g1z-62t
title: RedundantFinal incorrectly strips 'final' from nested class decls
status: review
type: bug
priority: normal
created_at: 2026-04-30T03:59:48Z
updated_at: 2026-04-30T04:00:10Z
sync:
    github:
        issue_number: "527"
        synced_at: "2026-04-30T04:23:37Z"
---

RedundantFinal removes 'final' from any member of a final class, including nested class declarations. But finality of the outer class only prevents subclassing of the outer type — a nested class is a distinct type that can still be subclassed independently, so 'final' on it is NOT redundant.

Example (current bug):

```swift
final class PreferFinalClasses {
    final class State { ... }   // 'final' is meaningful, should be kept
}
```

The existing test `nestedFinalClassInFinalClassTests` at Tests/SwiftiomaticTests/Rules/Redundant/RedundantFinalTests.swift:141 codifies the wrong behavior and must be flipped.

## Tasks

- [x] Skip nested class decls in `RedundantFinal.removeFinalFromMember`
- [x] Update `nestedFinalClassInFinalClass` test to assert 'final' is preserved on the nested class
- [x] Add a test asserting `final func` is still stripped when adjacent to a nested final class



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantFinal.swift`: skip `ClassDeclSyntax` members in `removeFinalFromMember`.
- `Tests/SwiftiomaticTests/Rules/Redundant/RedundantFinalTests.swift`: rewrote `nestedFinalClassInFinalClass` → `nestedFinalClassInFinalClassPreserved` (asserts `final` is kept, no findings); added `finalFuncStrippedAdjacentToNestedFinalClass` regression test.

Awaiting build/test verification.
