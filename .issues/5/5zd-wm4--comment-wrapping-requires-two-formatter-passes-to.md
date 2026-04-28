---
# 5zd-wm4
title: Comment wrapping requires two formatter passes to fit print width
status: completed
type: bug
priority: normal
created_at: 2026-04-27T21:31:16Z
updated_at: 2026-04-27T22:11:20Z
sync:
    github:
        issue_number: "478"
        synced_at: "2026-04-28T02:39:59Z"
---

## Problem

Running the formatter on a file with overlong comments often leaves them exceeding the configured print width on the first pass. A second invocation is required before comments are wrapped to fit.

## Expected

A single formatter pass should wrap comments to the configured print width.

## Reproduction

- [x] Find a file with comments longer than the print width
- [x] Run `sm format` once — observe comments still exceed the limit
- [x] Run `sm format` again — observe comments now wrap correctly
- [x] Construct a minimal test case capturing this idempotency failure

## Investigation notes

- Likely in the comment-handling path: `Sources/SwiftiomaticKit/Layout/Comment.swift`, `Sources/SwiftiomaticKit/Layout/Tokens/CommentMovingRewriter.swift`, or `LineLengthLimit`
- Check whether comment reflow runs before or after layout's print-width pass, and whether moved comments get re-measured in the same pass


## Summary of Changes

**Root cause.** `WrapSingleLineComments` and `ReflowComments` read the comment's column from leading trivia and decide whether to wrap by comparing `column + text.count > maxWidth`. But the pretty printer indents comments to the syntactic depth of the enclosing scope regardless of source column. A comment at source column 0 inside a function body lands at column N after layout. Pass 1 wrapped (or didn't wrap) using the stale column 0; layout then added indentation that pushed lines past `lineLength`. Pass 2 read the now-indented trivia and finally produced the correct wrap — hence the two-pass behavior.

**Fix.** Both rules now compute a conservative column floor from the syntactic indent depth (counting `CodeBlockSyntax`, `MemberBlockSyntax`, `ClosureExprSyntax`, `AccessorBlockSyntax`, `SwitchCaseSyntax` ancestors) and use `max(triviaColumn, syntacticIndentColumn)` when budgeting wraps. Wrap and reflow now produce a fixed point in a single pass.

**Files**
- `Sources/SwiftiomaticKit/Rules/Wrap/WrapSingleLineComments.swift` — added `syntacticIndentColumn(for:)`, threaded `layoutColumnFloor` into `tryWrap`.
- `Sources/SwiftiomaticKit/Rules/Comments/ReflowComments.swift` — same helper, applied to `effectiveColumn` used to compute `availableWidth`.
- `Tests/SwiftiomaticTests/Rules/Wrap/CommentWrapIdempotencyTests.swift` — new idempotency suite (4 tests; the 2 reproducing the bug now pass).

**Verification**
- 36/36 tests pass across `CommentWrapIdempotencyTests`, `WrapSingleLineCommentsTests`, `ReflowCommentsTests`.
- 3 pre-existing `GuardStmtTests` failures observed in the full suite are unrelated to this change (no comment involvement; modified rules are off by default; failures match in-progress edits in `Layout/`).
