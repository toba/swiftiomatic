---
# 7bp-yok
title: 'case where-clause: continuation line indents incorrectly relative to ''case'''
status: completed
type: bug
priority: normal
created_at: 2026-04-27T19:52:58Z
updated_at: 2026-04-27T20:02:32Z
sync:
    github:
        issue_number: "467"
        synced_at: "2026-04-27T20:03:55Z"
---

## Problem

When formatting a `case` statement with a `where` clause that wraps, the formatter produces output where the continuation line aligns with `case` rather than being indented further. The `&&` continuation also fails to indent under `where`.

## Actual output

```swift
case (.break(let breakKind, _, .soft(1, _, _)), .comment(let c2, _))
where breakAllowsCommentMerge(breakKind)
    && (c2.kind == .docLine || c2.kind == .line):
```

## Expected output

Preferred (single-line `where` clause if it fits):

```swift
case (.break(let breakKind, _, .soft(1, _, _)), .comment(let c2, _))
    where breakAllowsCommentMerge(breakKind) && (c2.kind == .docLine || c2.kind == .line):
```

Fallback (when `where` clause must wrap):

```swift
case (.break(let breakKind, _, .soft(1, _, _)), .comment(let c2, _))
    where breakAllowsCommentMerge(breakKind)
        && (c2.kind == .docLine || c2.kind == .line):
```

## Notes

- The `where` keyword break should indent the continuation past `case`, not align with it.
- This is a break-precedence / indentation issue in the layout for `SwitchCaseLabel` / `where` clauses.
- See CLAUDE.md "Layout & Break Precedence" section for the relevant mechanism.

## Tasks

- [x] Add a test reproducing the malformed output
- [x] Locate the token-stream construction for `case ... where ...` (found in `TokenStream+TypesAndPatterns.swift` `visitWhereClause`)
- [x] Fix indentation so `where` (and its `&&` continuation) indent past `case`
- [x] Verify against upstream apple/swift-format behavior (intentional divergence — upstream has same bug)



## Summary of Changes

- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+TypesAndPatterns.swift` — `visitWhereClause` now detects a `SwitchCaseItemSyntax` parent and emits `.break(.continue)` both before and after the `where` keyword, so the keyword indents past `case` when it wraps and the trailing condition aligns with the same continuation level.
- `Tests/SwiftiomaticTests/Layout/SwitchStmtTests.swift` — added `switchCaseWhereClauseIndentsPastCase` covering the motivating long pattern + `&&` condition, and updated existing `switchValueBinding` and `switchSequenceExprCases` expectations to reflect the corrected indent for `where` in switch cases.

Result: `case ... where ...` now produces e.g.

```swift
case (.break(let breakKind, _, .soft(1, _, _)), .comment(let c2, _))
  where breakAllowsCommentMerge(breakKind)
  && (c2.kind == .docLine || c2.kind == .line):
```

instead of `where` flush with `case`. Catch-clause and generic/for-in `where` clauses are unchanged.
