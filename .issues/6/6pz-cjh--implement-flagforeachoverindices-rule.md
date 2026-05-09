---
# 6pz-cjh
title: Implement FlagForEachOverIndices rule
status: completed
type: task
priority: normal
created_at: 2026-05-09T16:07:24Z
updated_at: 2026-05-09T16:10:26Z
parent: z75-gax
sync:
    github:
        issue_number: "684"
        synced_at: "2026-05-09T17:07:18Z"
---

Implement `FlagForEachOverIndices` per item 1 of z75-gax.

## Plan

- New rule at `Sources/SwiftiomaticKit/Rules/Swiftui/FlagForEachOverIndices.swift`.
- `LintSyntaxRule`, group `.swiftui`.
- Visit `FunctionCallExprSyntax`. Trigger when callee is `ForEach` and the first positional argument matches `isIntegerIndexedReceiver` (`<expr>.indices`, `a..<b`, `a...b`, `Range(...)`). Diagnose on the first argument's expression. Ignore the `id:` argument entirely.
- Reuse the existing `isIntegerIndexedReceiver` shape — copy into the new rule (private), keep the original in `FlagForEachIDSelfInView` so its exemption stays in place.
- Message: "'ForEach' over indices loses row identity on insert/remove — use 'ForEach(Array(<collection>.enumerated()), id: \\.element.id)'".

## Test plan (test-first)

Add `Tests/SwiftiomaticTests/Rules/FlagForEachOverIndicesTests.swift` with cases:

Should fire:
- `ForEach(items.indices, id: \.self) { i in ... }`
- `ForEach(items.indices) { i in ... }` (no id)
- `ForEach(0..<items.count, id: \.self) { i in ... }`
- `ForEach(0..<n) { i in ... }`
- `ForEach(0...9) { i in ... }`
- `ForEach(Range(0..<n)) { i in ... }`

Should NOT fire:
- `ForEach(items, id: \.self) { ... }` — element collection, owned by FlagForEachIDSelfInView.
- `ForEach(items) { ... }` — fine.
- `ForEach(items.enumerated().map { ... }, id: \.0) { ... }` — non-integer-indexed.

## Coordination

- Confirm `FlagForEachIDSelfInView` does NOT fire on integer-indexed receivers after this rule lands (run `FlagForEachIDSelfInViewTests` filtered).

## Done when

- Both `FlagForEachOverIndicesTests` and `FlagForEachIDSelfInViewTests` pass.
- Full suite passes.



## Summary of Changes

- Added `Sources/SwiftiomaticKit/Rules/Swiftui/FlagForEachOverIndices.swift` — `LintSyntaxRule` keyed on receiver shape (`.indices`, `a..<b`, `a...b`, `Range(...)`); ignores the `id:` argument so it's orthogonal to `FlagForEachIDSelfInView`.
- Added `Tests/SwiftiomaticTests/Rules/FlagForEachOverIndicesTests.swift` (10 cases — 6 fire, 4 don't).
- `FlagForEachIDSelfInView` unchanged; its existing `isIntegerIndexedReceiver` exemption hands those cases to the new rule. Both suites green; full 3298-test suite passes.
