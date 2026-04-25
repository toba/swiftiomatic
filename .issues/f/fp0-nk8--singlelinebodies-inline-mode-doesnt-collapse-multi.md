---
# fp0-nk8
title: singleLineBodies inline mode doesn't collapse multi-line conditions when body fits
status: completed
type: bug
priority: normal
created_at: 2026-04-25T19:24:02Z
updated_at: 2026-04-25T19:35:05Z
sync:
    github:
        issue_number: "408"
        synced_at: "2026-04-25T19:53:35Z"
---

When `singleLineBodies` is set to `inline`, the formatter should collapse the body onto the closing-brace line when the body is short enough to fit alongside the (possibly multi-line) condition.

## Example

Current output:

```swift
if let funcCall = parent.as(FunctionCallExprSyntax.self),
   funcCall.calledExpression.id == node.id
{
    return false
}
```

Expected output:

```swift
if let funcCall = parent.as(FunctionCallExprSyntax.self),
   funcCall.calledExpression.id == node.id { return false }
```

## Notes

- The condition spans multiple lines, but the body (`return false`) is a single short statement.
- In `inline` mode the open brace should stay on the last condition line and the body + close brace should follow on the same line if width permits.
- Currently the brace is being pushed to its own line (Allman-style), which is incorrect for `inline` mode.


## Summary of Changes

`Sources/SwiftiomaticKit/Rules/Wrap/WrapSingleLineBodies.swift`

- `prefixLength(from:to:)` rewritten to use column-based source locations. For a multi-line prefix the relevant length is the LAST line — the line the inlined body will join. If `{` currently sits on its own line, the result reflects gluing the brace next to the previous token with a single space.
- `inliningBody(_:)` now strips the brace's leading-trivia newline+indent (replacing it with a single space) when the brace was on its own line. Without this, the rewriter would keep the Allman newline and emit `cond\n{ body }`.

Only applies to simple `if () { }` (existing `node.elseBody == nil` guard); `if/else` chains were and remain non-inlined.

## Tests added

`Tests/SwiftiomaticTests/Rules/Wrap/SingleLineBodiesTests.swift`

- `multiLineConditionWithBraceOnOwnLineInlines` — Allman-style brace gets pulled up.
- `multiLineConditionWithBraceOnLastConditionLineInlines` — brace already on last condition line, body gets inlined.
- `multiLineConditionTooLongNotInlined` — line-length budget still respected against the LAST line of the prefix.

Full SingleLineBodies suite: 77 passed.
