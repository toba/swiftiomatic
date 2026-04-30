---
# rvt-vyu
title: WarnSwapThenRemoveAll
status: completed
type: feature
priority: normal
created_at: 2026-04-30T23:05:21Z
updated_at: 2026-04-30T23:10:05Z
parent: 7h4-72k
sync:
    github:
        issue_number: "577"
        synced_at: "2026-04-30T23:13:22Z"
---

Lint the alternating-buffer pattern `swap(&a, &b); a.removeAll(...)` (or `b.removeAll` after swap of `a, b`). It's almost always a parser/double-buffer hand-roll that loses CoW guarantees and is brittle.

## Decisions

- Group: `.idioms`
- Default: `.warn`
- Lint-only.
- Trigger: a code block where two consecutive statements are: (1) a call to `swap(&X, &Y)` and (2) `X.removeAll(...)` or `Y.removeAll(...)` on the same X or Y.

## Plan

- [x] Failing test
- [x] Implement `WarnSwapThenRemoveAll`
- [x] Verify test passes; regenerate schema



## Summary of Changes

- LintSyntaxRule on `CodeBlockItemListSyntax`. Looks at consecutive item pairs: `swap(&X, &Y)` followed by `X.removeAll(...)` or `Y.removeAll(...)`.
- 5/5 tests passing.
- Schema regenerated.
