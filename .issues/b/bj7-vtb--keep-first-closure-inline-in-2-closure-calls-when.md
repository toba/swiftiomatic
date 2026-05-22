---
# bj7-vtb
title: keep first closure inline in 2-closure calls when it fits
status: completed
type: bug
priority: normal
created_at: 2026-05-22T19:39:51Z
updated_at: 2026-05-22T19:42:45Z
sync:
    github:
        issue_number: "700"
        synced_at: "2026-05-22T19:47:14Z"
---

When a function call has exactly two trailing closures (one unlabeled + one labeled, e.g. `With { expr } query: { … }`), the formatter always forces the first closure to multi-line even if the user wrote it inline and it fits.

Fix: in `visitFunctionCallExpr`, only add the trailing closure to `forcedBreakingClosures` when there are 2+ additional trailing closures (3+ total). For exactly 2 closures, leave the first closure's newline behavior as `.elective` so it respects what the user typed.

3+ closures: all break to their own lines (current behavior preserved).

- [x] Add failing test for 2-closure inline-first case
- [x] Fix `TokenStream+Collections.swift` visitFunctionCallExpr
- [x] Confirm test passes
- [x] Run ClosureExprTests to check for regressions

## Summary of Changes

In `visitFunctionCallExpr`, changed the `forcedBreakingClosures` insertion for the unlabeled trailing closure to only fire when `additionalTrailingClosures.count > 1` (3+ total closures). For exactly 2 closures the first closure's newline behavior is now `.elective`, so the formatter respects whether the user wrote it inline or multi-line. 3+ closures continue to all break as before. Added `twoLabeledTrailingClosures` test in `ClosureExprTests.swift`.
