---
# cda-6ba
title: guard with single-line body should wrap body onto next line, not split condition
status: review
type: bug
priority: normal
created_at: 2026-04-27T20:45:35Z
updated_at: 2026-04-27T21:02:27Z
sync:
    github:
        issue_number: "471"
        synced_at: "2026-04-28T02:39:59Z"
---

## Problem

The formatter wraps a `guard` statement by splitting the condition before `else`, leaving the body on its own line:

```swift
guard column + text.count > maxWidth
else { return WrapResult(didChange: false, advance: 1, originalIndex: 0) }
```

## Expected

The body should be wrapped (single-line body expanded to multi-line) while keeping the condition and `else {` together:

```swift
guard column + text.count > maxWidth else {
    return WrapResult(didChange: false, advance: 1, originalIndex: 0)
}
```

## Notes

- Wrapping the body is preferable to wrapping before `else` (assignment/guard keyword breaks are last-resort precedence per CLAUDE.md).
- Likely interaction between `WrapSingleLineBodies` / guard layout in `TokenStreamCreator`.
- Add a failing test reproducing the input and asserting the expected output before fixing.



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/LineBreaks/BeforeGuardConditions.swift`: in the inline-single-statement branch (`isInlineSingleStatementBody`), moved `.close` from `after(node.body.rightBrace)` to `before(node.body.leftBrace)`. This shrinks the chunk for the `.break(.same)` before `else` from the entire `else { stmt }` form down to just `else`. The body's own breaks (emitted by `arrangeBracesAndContents`) now fire first when the inline form overflows, so the body wraps inside the braces while `else {` stays glued to the conditions — matching CLAUDE.md's last-resort precedence for keyword breaks.
- `Tests/SwiftiomaticTests/Layout/GuardStmtTests.swift`:
  - Added `guardWithInlineBodyWrapsBodyNotElse` reproducing the reported case.
  - Updated `breaksElseWhenInlineBodyExceedsLineLength` to reflect the new (correct) body-wrapping behaviour rather than the previous body-stays-inline behaviour.
  - Updated the second case of `optionalBindingConditions` for the same reason — `else { return nil }` now stays attached to the closing condition, with the body wrapping inside the braces.

## Verification

Test suite not run in this session — user should run the GuardStmtTests filter and the full suite via xc-mcp at session end.
