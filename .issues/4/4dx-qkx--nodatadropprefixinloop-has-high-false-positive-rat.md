---
# 4dx-qkx
title: noDataDropPrefixInLoop has high false-positive rate on String/non-Data values
status: completed
type: bug
priority: normal
created_at: 2026-05-01T00:30:40Z
updated_at: 2026-05-01T02:11:13Z
sync:
    github:
        issue_number: "594"
        synced_at: "2026-05-01T02:12:28Z"
---

Discovered while running c12-swt dogfood: `noDataDropPrefixInLoop` flagged 36 sites in `Sources/`, most of which are `String.prefix(1)`, `String.dropFirst()`, etc. on values unrelated to the iterated collection.

Examples:

```
Sources/SwiftiomaticKit/Configuration/ConfigurationRegistry.swift:16:30: warning: [noDataDropPrefixInLoop] '.prefix' inside a loop copies the collection on every iteration
Sources/SwiftiomaticKit/Configuration/ConfigurationRegistry.swift:16:64: warning: [noDataDropPrefixInLoop] '.dropFirst' inside a loop copies the collection on every iteration
```

The actual line: `let derivedKey = typeName.prefix(1).lowercased() + typeName.dropFirst()` — these are short String operations on a `typeName` local variable, not a quadratic copy of the iterated collection.

The rule should at minimum:
1. Restrict to `Data` (its name suggests so), OR
2. Only fire when the receiver of `.dropFirst`/`.prefix` is the same identifier as the loop's iterated collection or a value derived from it inside the loop body

Currently the rule has been disabled for this project.


## Summary of Changes

Restricted `noDataDropPrefixInLoop` to fire only when the slice-method receiver is plausibly the iterated value or a value being shrunk across iterations. The rule now collects a `tracked` set of identifiers per loop:

- For-in: identifiers in the sequence expression + bindings introduced by the pattern (handles tuple destructuring)
- While: identifiers in the conditions
- Both: identifiers assigned to inside the loop body (catches the `data = data.dropFirst()` shrink-in-place pattern)

A new `CopyingSliceCollector` resolves the leftmost identifier of the receiver (handling `.suffix(8).reversed()` chains) and only flags hits where that identifier is in `tracked`. Closure / nested-loop scopes are still skipped as before.

This eliminates the false positives reported in the issue (e.g. `let derivedKey = typeName.prefix(1).lowercased() + typeName.dropFirst()` inside a `for` loop where `typeName` is unrelated to the iterated collection) while keeping existing true positives — `data = data.dropFirst()` in a `while !data.isEmpty` loop, `chunk.prefix(8)` in `for chunk in chunks`, `buffer = buffer.dropLast()` in `while keep`.

Files:
- `Sources/SwiftiomaticKit/Rules/Idioms/NoDataDropPrefixInLoop.swift` — rewrote
- `Tests/SwiftiomaticTests/Rules/NoDataDropPrefixInLoopTests.swift` — added `sliceOnUnrelatedIdentifierNotFlagged` and `sliceOnUnrelatedIdentifierInWhileNotFlagged`

All 7 rule tests pass; all 3141 project tests pass.
