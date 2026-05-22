---
# itl-f2e
title: LayoutSingleLineBodies (inline mode) keeps body inline when a wrapped generic where clause forces brace onto its own line
status: completed
type: bug
priority: normal
created_at: 2026-05-22T02:18:03Z
updated_at: 2026-05-22T02:46:28Z
sync:
    github:
        issue_number: "694"
        synced_at: "2026-05-22T02:46:57Z"
---

In inline mode, a function/init/subscript whose generic `where` clause is wrapped onto its own line should have its body wrapped onto new lines, not kept inline. The wrapped where clause forces the opening brace onto its own line, so an inline `{ body }` reads poorly.

Trigger: a wrapped generic constraint (where keyword preceded by a newline).

Expected:
```
func jsonArrayLength<Element: Codable>() -> some QueryExpression<Int>
    where QueryValue == [Element].JSONRepresentation
{
    QueryFunction("json_array_length", self)
}
```

## Summary of Changes

`LayoutSingleLineBodies` (inline mode) now wraps the body of a function/init/subscript when its generic `where` clause is wrapped onto its own line (`where` keyword preceded by a newline).

- Added `hasWrappedGenericWhereClause(_:)` helper.
- `inlineFunction`/`inlineInit`/`inlineSubscript` redirect to their `wrap*` counterpart when the where clause is wrapped, so the body is placed on new lines instead of glued to the lone brace.
- Inline `where` clauses (on the signature line) still inline normally.

Tests added in `SingleLineBodiesInlineTests`: `functionWithWrappedWhereClauseWrapsBody`, `functionWithInlineWhereClauseStillInlines`. Full `SingleLineBodies` suite: 103 passed.
