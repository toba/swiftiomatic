---
# uth-yru
title: Restore upstream verbatim ExpressionSegment emission; solve multiline-interpolation indent in layout pass
status: completed
type: task
priority: normal
created_at: 2026-05-08T16:42:01Z
updated_at: 2026-05-08T16:52:10Z
sync:
    github:
        issue_number: "663"
        synced_at: "2026-05-08T16:52:46Z"
---

Follow-up to ugi-3p0.

Apple's swift-format `visit(ExpressionSegmentSyntax)` emits `node.description` verbatim (no token rewalk, no whitespace mangling). Swiftiomatic replaced this with a custom token walk in `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Closures.swift` (`visitExpressionSegment`) to fix issue 9yv-e8j ("Insufficient indentation" when a pre-split interpolation's inner newlines pushed subsequent string segments below the closing `\"\"\"` indent).

The custom walk has now produced two regressions of its own:

- 9yv-e8j (reopened, fixed): preserved newlines dropped indent below `\"\"\"`.
- ugi-3p0 (fixed): collapsing newlines reclassified binary operators (`type\\n?? outputType` → `type?? outputType`, postfix → syntax error).

Each fix is reactive. Both stem from the same root cause: we're rewriting code inside a string literal at the token level. Even with whitespace heuristics, the formatter cannot know whether the literal contents are Swift, SQL, JSON, or other, so reformatting them is unsafe in general.

## Goal

Restore upstream-faithful behavior:

1. `visitExpressionSegment` emits `node.description` verbatim (single `.syntax` token).
2. Solve the original "Insufficient indentation" problem in the multiline-string layout pass — re-indent trailing string segments after a multi-line interpolation so they don't fall below the closing `\"\"\"` column. This is a layout-level concern, not a token-emission one.

## Scope

- Revert the token-rebuild loop in `visitExpressionSegment`.
- Audit `StringLiteralExprSyntax` handling in `TokenStream+Strings.swift` and `LayoutCoordinator` for where multi-line content indent is computed; insert re-indent logic for segments that follow a multi-line interpolation.
- Cover both `reflow=automatic` and `reflow=never` configurations.

## Tests to keep green

- `StringTests.multilineStringWithInterpolationsNotMangledWithNeverReflow`
- `StringTests.multilineStringWithPreSplitInterpolationKeepsValidIndent`
- `StringTests.multilineStringPreSplitInterpolationOperatorBoundary` (the ugi-3p0 regression test)

Also: ensure no other code inside multi-line literals is reformatted. Add a SQL-keyword-spacing test to assert non-Swift content is left alone.



## Summary of Changes

`Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Closures.swift` `visitExpressionSegment` now matches upstream apple/swift-format: emit `node.description` verbatim. Single-line interpolations are emitted as one `.syntax` token. Multi-line interpolations are split on `\n` and emitted as a sequence of `.syntax` tokens with `.break(breakKind, newlines: .hard)` between each — the breakKind comes from `pendingMultilineStringBreakKinds` for the parent `StringLiteralExprSyntax`, so the printer re-indents each continuation line to the segment column (≥ closing `\"\"\"` column). Same mechanism upstream uses for `StringSegmentSyntax`.

Two existing tests in `Tests/SwiftiomaticTests/Layout/StringTests.swift` updated:
- `multilineStringWithPreSplitInterpolationKeepsValidIndent` (9yv-e8j regression)
- `multilineStringPreSplitInterpolationOperatorBoundary` (ugi-3p0 regression)

Both now assert the verbatim-with-reindent output (preserves source structure) instead of the prior collapse-to-one-line behavior. Both outputs are valid Swift.

### Why this is better than the prior collapse + heuristic

- Eliminates the token-adjacency heuristic class of bugs (no token rewalk, no merging).
- Preserves macro authors' deliberate multi-line interpolation formatting (5+ named-arg calls in DeclSyntax literals stay readable).
- Smaller diff vs upstream — easier to maintain.

### Verification

Full suite: 3275 passed, 0 failed.
