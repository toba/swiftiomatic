---
# 83k-hv9
title: wrapTernaryBranches fires on ternary that fits on one line
status: completed
type: bug
priority: normal
created_at: 2026-05-01T21:49:13Z
updated_at: 2026-05-01T21:54:32Z
sync:
    github:
        issue_number: "614"
        synced_at: "2026-05-01T23:12:04Z"
---

## Repro

```swift
var urlEncoded: String {
    isEmpty ? "" : "?"
        + map { key, value in "\(key)=\(value.description.urlEncoded)" }
        .joined(separator: "&")
}
```

Xcode shows a `wrapTernaryBranches` warning on the `isEmpty ? "" : "?"` line: "wrap ternary branch onto a new line". The ternary itself (`isEmpty ? "" : "?"`) fits comfortably on one line — the rule should not fire.

The likely confusion is that the ternary is the **left operand** of a `+` expression whose right operand is a multi-line chain. The rule may be looking at the enclosing expression's wrapped state rather than the ternary expression itself, or measuring the ternary's containing line including the trailing `+ map { … }` continuation.

## Expected

`wrapTernaryBranches` should only fire when the ternary expression's *own* operands (condition / then / else) cause it to overflow the print width on a single line. `isEmpty ? "" : "?"` is well under width and should be left alone.

## Files

- `Sources/SwiftiomaticKit/Rules/Wrap/WrapTernaryBranches.swift`
- Look at how the rule measures fit and whether it considers the ternary in isolation or as part of the enclosing infix expression.

## Test plan

- Add a fixture with a ternary used as one operand of a multi-line infix expression where the ternary itself is short — assert no finding.
- Existing wrap-when-overflowing case stays green.



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Wrap/WrapTernaryBranches.swift` — added a short-circuit before the collapsed-length calculation: if the source lines that already host `?` and `:` both fit within `lineLength`, skip the wrap. New helper `sourceLineLength(at:converter:)` measures actual source-line length via `SourceLocationConverter.position(ofLine:column:)`.
- `Tests/SwiftiomaticTests/Rules/Wrap/WrapTernaryBranchesTests.swift` — added `ternaryWithMultiLineRHSOperandNotWrapped` covering the user's exact `isEmpty ? "" : "?" + map { … }.joined(...)` pattern.

## Root cause

Ternary `?:` precedence is lower than `+` in Swift, so `cond ? a : b + chain` parses as `cond ? a : (b + chain)`. When the `+ chain` part was a multi-line method chain, the ternary's `else` branch span included all of it, and `singleLineLength(of:)` (which collapses internal whitespace) measured the whole ternary as a single huge string that overflowed `lineLength`. The fix bypasses that calculation when both operator lines already fit in source — the operands' wrapping is independent and not the ternary's concern.
