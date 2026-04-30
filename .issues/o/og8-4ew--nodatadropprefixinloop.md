---
# og8-4ew
title: NoDataDropPrefixInLoop
status: completed
type: feature
priority: normal
created_at: 2026-04-30T22:44:26Z
updated_at: 2026-04-30T22:49:13Z
parent: 7h4-72k
sync:
    github:
        issue_number: "585"
        synced_at: "2026-04-30T23:13:22Z"
---

Lint `<expr>.dropFirst(...)` / `<expr>.prefix(...)` calls whose ancestor is a `for-in` or `while` loop. On `Data` (and Array) these copy on each iteration, producing O(n²) cost. Suggest indexed slicing or `startIndex` advancement.

## Decisions

- Group: `.idioms`
- Default: `.warn`
- Lint-only.
- Trigger: any `<expr>.dropFirst`/`<expr>.prefix`/`<expr>.dropLast`/`<expr>.suffix` call inside a ForStmt or WhileStmt body, excluding nested closures.

## Plan

- [x] Failing test
- [x] Implement `NoDataDropPrefixInLoop`
- [x] Verify test passes; regenerate schema



## Summary of Changes

- LintSyntaxRule on ForStmt/WhileStmt. Walks loop body with `CopyingSliceCollector`, skipping nested closures and nested loops.
- 5/5 tests passing.
- Schema regenerated.
