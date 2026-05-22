---
# gar-3c1
title: fix multipleTrailingClosures CI failure from 2-closure elective change
status: completed
type: bug
priority: normal
created_at: 2026-05-22T22:06:55Z
updated_at: 2026-05-22T22:14:05Z
---

The bj7-vtb change (keep first closure inline in 2-closure calls) broke the existing \`multipleTrailingClosures\` test in FunctionCallTests.swift (linelength: 23).

## Root Cause (traced)

Scan length calculation: when second closure uses \`.soft\` (forced), \`total += maxLineLength\` in the scan, inflating the first closure's break length and forcing it to fire. With \`.elective\` (my change), \`total += size (1)\`, so the first closure's break length stays small and doesn't fire — stays inline.

The indentation bug: when the first closure stays inline and the second closure's \`.break(.open)\` fires for line-length reasons, \`d\` lands at column 0 instead of column 2.

Theoretical root cause traced to \`activeOpenBreaks\` and the "same-line" suppression in LayoutCoordinator.swift lines 237-248:
- When the second closure's \`.break(.open)\` is processed on the same line as some enclosing open break, \`contributesBlockIndent\` of the enclosing break is suppressed
- When the second closure's break then fires, the indentation contribution is 0 instead of 2

## Current fix state

In \`TokenStream+Collections.swift visitFunctionCallExpr\`: changed to \`node.additionalTrailingClosures.count > 1\` for the forcedBreakingClosures insertion (i.e. both closures are elective for the 2-closure case).

This fixes the user's actual case (multi-statement second closure — \`twoLabeledTrailingClosures\` passes) but fails \`multipleTrailingClosures\` at linelength 23 where BOTH closures are single-statement.

## Key test cases from multipleTrailingClosures (linelength: 23)

New actual output:
- \`a = f { b } c: { d }\` (20 chars) → stays inline ✓
- \`let a = f { b } c: { d }\` (24 chars) → \`let a = f { b } c: {\nd\n}\` with d at column 0 ✗
- \`let a = foo { b in b } c: { d in d }\` → \`let a = foo { b in b\n} c: { d in d }\`
- \`let a = foo { abcdefg in b } c: { d in d }\` → \`let a = foo {\n  abcdefg in b\n} c: { d in d }\`

## Options to investigate

A. Fix the indentation bug in LayoutCoordinator: when the second closure's break fires after first stays inline, need correct indent. The "same-line" check uses \`?? 0\` fallback — but lineNumber starts at 1, so nil→0 doesn't spuriously match. Must be something else setting wrong indent.

B. Use \`ignoresDiscretionary: true\` for the elective behavior so line-length doesn't fire the break (only source newlines do). This would mean a 1-char overrun is accepted when both closures are short.

C. Only apply the elective behavior when source had the first closure inline (check trivia). Then update \`visitClosureExpr\` to handle this.

D. Keep the forced behavior but add a post-pass to collapse the first closure inline (not currently possible since no post-printer hook exists).

E. Update test to reflect new behavior. Cases 3 and 4 look OK. Case 2 (column 0) is the only genuinely broken case — that needs fixing regardless of approach.

## Files changed

- Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Collections.swift (visitFunctionCallExpr)
- Tests/SwiftiomaticTests/Layout/ClosureExprTests.swift (twoLabeledTrailingClosures test added)
- Tests/SwiftiomaticTests/Layout/FunctionCallTests.swift (multipleTrailingClosures needs update)

TODO:
- [x] Investigate the column-0 indentation bug for the edge case
- [x] Update multipleTrailingClosures test expectations
- [x] Run full suite to confirm no regressions


## Summary of Changes

The suspected column-0 indentation bug turned out not to exist. Reproducing `let a = f { b } c: { d }` (linelength 23) in isolation and via the full 4-line input both place the second closure body `d` correctly at column 2 — the earlier diff showing `d` at column 0 was a diff-rendering artifact (context lines without +/- prefix), not actual output.

The LayoutCoordinator needed no change. The 2-closure elective behavior from bj7-vtb produces sound, per-closure-independent output:

```
a = f { b } c: { d }
let a = f { b } c: {
  d
}
let a = foo { b in b
} c: { d in d }
let a = foo {
  abcdefg in b
} c: { d in d }
```

Fix was limited to updating the `multipleTrailingClosures` test (FunctionCallTests.swift) expectations to match the new behavior, with a comment explaining the per-closure breaking rationale. Full suite: 3380 passed, 0 failed.
