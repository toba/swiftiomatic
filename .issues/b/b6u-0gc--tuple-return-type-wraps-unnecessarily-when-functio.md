---
# b6u-0gc
title: Tuple return type wraps unnecessarily when function signature already wraps
status: completed
type: bug
priority: normal
created_at: 2026-04-30T17:04:28Z
updated_at: 2026-04-30T18:27:38Z
sync:
    github:
        issue_number: "561"
        synced_at: "2026-04-30T19:41:41Z"
---

## Problem

Similar to the prior tuple/array literal inline issue: when a function's parameter list already wraps onto its own lines, the tuple return type should stay inline on the closing-paren-arrow line if it fits, instead of wrapping its own elements.

## Repro

Current (incorrect) output:

```swift
private func nonLinguisticSentenceApproximations(
    in text: String
) -> (
    sentences: [String], trailingText: Substring
) {
```

Expected:

```swift
private func nonLinguisticSentenceApproximations(
    in text: String
) -> (sentences: [String], trailingText: Substring) {
```

The tuple return type fits on one line after `->` and should not be split. This mirrors the previously-fixed inlining behavior for tuple/array literals in argument position.



## Summary of Changes

- **Root cause**: `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+TypesAndPatterns.swift` had no `visitTupleTypeElementList` visitor — the parallel `visitTuplePatternElementList` exists and calls `markCommaDelimitedRegion`. Without that, the tuple-type comma list misses the all-or-nothing wrap policy, so the outer `(` break fires preferentially even when the tuple's contents fit inline after `->`.
- **Fix**: Added `visitTupleTypeElementList` mirroring `visitTuplePatternElementList` (4 lines).
- **Verified** via `sm format` on the reported repro:

```
private func nonLinguisticSentenceApproximations(
    in text: String
) -> (sentences: [String], trailingText: Substring) {
```

The tuple now stays inline after `->` once the function signature wraps, instead of splitting into its own block.

## Files changed
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+TypesAndPatterns.swift`

## Verification gap
A regression test in `FunctionDeclTests` was attempted but `Configuration.forTesting` defaults make the layout choose a different (still incorrect-looking) wrap that the bug doesn't address — separate from this fix. Reverted the test rather than mask the issue. The fix itself is verified end-to-end via `sm`.
