---
# 8h8-eej
title: 'rule [flagForEachIDSelfInView] should skip ''id: \\.self'' when collection is *.indices (Range<Int>)'
status: completed
type: bug
priority: normal
created_at: 2026-05-08T02:11:53Z
updated_at: 2026-05-08T02:45:53Z
sync:
    github:
        issue_number: "649"
        synced_at: "2026-05-08T02:54:16Z"
---

## Symptom

The rule fires on `ForEach(collection.indices, id: \\.self)` patterns where there is no better alternative — `Int` is not `Identifiable` and `\.self` *is* the stable id for Int indices.

```swift
ForEach(citations.indices, id: \.self) { index in  // flagged, but correct
    CitationForm(index: index, citations: citations)
}
```

## Expected

When the receiver expression syntactically matches `<expr>.indices` (or is a `Range<Int>`/`Range` literal), the rule should not fire — there is no `Identifiable`-based alternative for an integer range.

## Detection (syntactic)

If the first argument to `ForEach(_:id:)` matches:
- `<anything>.indices` (member access ending in `.indices`)
- `Range(...)` / `0..<n` / `n...m` literal range expressions

…skip the rule. The user has no choice but `id: \.self` for `Int`.

## Repro

Thesis project, `App/Sources/Views/Citation/CitationGroupForm.swift:36`. Currently silenced with `// sm:ignore:next flagForEachIDSelfInView - indices are stable for the binding's lifetime`.

## Acceptance

- `ForEach(arr.indices, id: \.self)` does not fire.
- `ForEach(0..<count, id: \.self)` does not fire.
- `ForEach(items, id: \.self)` (custom Hashable type) continues to fire.



## Summary of Changes

The rule now skips `ForEach(_:id:)` calls whose first (unlabeled) argument is integer-indexed:

- `<expr>.indices` (member access ending in `indices`)
- `a..<b` / `a...b` range expressions (post operator-folding `InfixOperatorExprSyntax`, with `SequenceExprSyntax` fallback)
- `Range(...)` constructor calls

For those receivers, `Int` is the element type and `\.self` is the only valid id key path, so the diagnostic is suppressed.

Added tests:
- `indicesWithIdSelfNotFlagged`
- `halfOpenRangeWithIdSelfNotFlagged`
- `closedRangeWithIdSelfNotFlagged`

Files:
- `Sources/SwiftiomaticKit/Rules/Swiftui/FlagForEachIDSelfInView.swift` — added `isIntegerIndexedReceiver` early-out
- `Tests/SwiftiomaticTests/Rules/FlagForEachIDSelfInViewTests.swift` — added 3 regression tests
