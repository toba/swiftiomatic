---
# j0l-do5
title: 'for-where header wrap: indent where as continuation and force brace to own line'
status: completed
type: bug
priority: normal
created_at: 2026-05-22T22:44:53Z
updated_at: 2026-05-22T23:00:10Z
sync:
    github:
        issue_number: "702"
        synced_at: "2026-05-22T23:01:41Z"
---

## Problem

When a `for ... where ...` loop header wraps, the current (upstream-matching) layout puts `where` at the same indent as `for` and keeps `{` inline with the where clause:

```swift
for run in runs
where run.fontStyle != nil || run.verticalPlacement != nil || run.prevent != nil {
    ...
}
```

This reverses ojf-4w0, which originally requested the continuation-indented form but was resolved to match upstream.

## Expected (per user, 2026-05-22)

```swift
for run in runs
    where run.fontStyle != nil || run.verticalPlacement != nil || run.prevent != nil
{
    ...
}
```

- `where` indented as a continuation of the wrapped header
- `{` always drops to its own line when the where clause wraps

## Tasks

- [x] Write/adjust tests asserting indented where + brace on own line
- [x] Implement in visitForStmt token-stream construction
- [x] Update forWhereWrapsHeader + forWhereLoop + forLoopFullWrap + forStatementWithNestedExpressions expectations
- [x] Full suite green

## Summary of Changes

`visitForStmt` (TokenStream+ControlFlow.swift) now owns the `for ... where ...` header layout when a `whereClause` is present. It wraps the `in <sequence> where <condition>` header tail in a `.consistent` group; once that group goes multi-line (the where clause overflows or carries a discretionary newline) the brace's preceding reset break inherits the force-break flag, dropping `{` onto its own line. The `in <sequence>` part is isolated in its own nested inconsistent group so the `in` break's chunk is bounded (no premature `for x\n in y` wrap) and it isn't force-broken alongside `where`. The `where` keyword indents as a continuation. `visitWhereClause` (TokenStream+TypesAndPatterns.swift) now early-returns for a `ForStmtSyntax` parent to avoid double-emitting break tokens.

Reverses ojf-4w0's upstream-matching resolution per user request (2026-05-22). Tests: added `forWhereIndentsAndDropsBrace` and `forWhereDiscretionaryNewlineDropsBrace`; updated `forWhereWrapsHeader`, `forWhereLoop`, `forLoopFullWrap`, `forStatementWithNestedExpressions`. Full suite green (3382 passed).
