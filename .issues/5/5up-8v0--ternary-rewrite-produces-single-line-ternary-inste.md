---
# 5up-8v0
title: Ternary rewrite produces single-line ternary instead of wrapped form
status: completed
type: bug
priority: normal
created_at: 2026-04-30T17:02:55Z
updated_at: 2026-04-30T18:27:39Z
sync:
    github:
        issue_number: "560"
        synced_at: "2026-04-30T19:41:41Z"
---

## Problem

The rule that rewrites if/else returns into a ternary expression produces output that does not respect the ternary wrapping rules. When the result exceeds the line limit, it should wrap with `?` and `:` each on their own indented line.

## Repro

Input:

```swift
if hasTrailingText {
    return (sentences: [], trailingText: text[...])
} else {
    return (sentences: [text], trailingText: "")
}
```

Current (incorrect) output:

```swift
return hasTrailingText
    ? (sentences: [], trailingText: text[...]) : (sentences: [text], trailingText: "")
```

Expected output (per ternary wrapping rules):

```swift
return hasTrailingText
    ? (sentences: [], trailingText: text[...])
    : (sentences: [text], trailingText: "")
```

The `?` branch wraps but the `:` branch stays inline on the same line, exceeding the line limit and violating the ternary layout rule that puts each branch on its own line once any wrapping occurs.

## Notes

- Likely interaction between the if/else→ternary rewriter and the layout pass: the rewritten ternary is not being re-laid out under the same wrap policy that an authored ternary would use, OR the ternary layout itself isn't enforcing 'wrap both branches once either wraps'.



## Summary of Changes

- **Root cause**: `PreferTernary` synthesizes a `TernaryExprSyntax` from a `CodeBlockItemListSyntax` rewrite. Because `SyntaxRewriter` walks children before parents, `WrapTernary`'s `visit(_ node: TernaryExprSyntax)` never fires on the synthesized node. Without the discretionary newlines that `WrapTernary` inserts, the pretty printer wraps `?` (driven by assignment-RHS / continuation breaks) but leaves `:` inline.
- **Fix**: In `Sources/SwiftiomaticKit/Rules/Conditions/PreferTernary.swift`, `buildTernaryExpr` now captures the original condition's column via `startLocation(converter:)` *before* detaching it, then mirrors `WrapTernary`'s policy inline — inserting `.newline` leading trivia on both `?` and `:` when `(anchorCol - 1) + singleLineLength > LineLength`. Capturing the column up front is required because `startLocation` on a detached/synthesized node is unreliable.
- **Verified** via `sm format` on the reported repro: both `?` and `:` now wrap to their own continuation-indented lines.
- Updated three existing `PreferTernaryTests` expected outputs to reflect the new (correct) wrapping for cases whose ternary now exceeds the line length.

## Files changed
- `Sources/SwiftiomaticKit/Rules/Conditions/PreferTernary.swift`
- `Tests/SwiftiomaticTests/Rules/PreferTernaryTests.swift`

## Verification gap
Test binary couldn't be rebuilt at session end due to an unrelated build break in another agent's work (`StructuralFormatRule` made `final`). Earlier, `PreferTernaryTests` passed (21/21) before that break landed.
