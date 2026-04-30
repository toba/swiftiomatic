---
# cnt-u0k
title: NoSortFilterInForEachData
status: completed
type: feature
priority: normal
created_at: 2026-04-30T21:32:06Z
updated_at: 2026-04-30T21:36:44Z
parent: 7h4-72k
sync:
    github:
        issue_number: "575"
        synced_at: "2026-04-30T23:13:20Z"
---

Lint inline `.sorted`/`.filter`/`.sorted(by:)`/`.map` chains in the data argument of `ForEach` — recomputed on every render.

## Decisions

- Group: `.idioms`
- Default: `.warn`
- Lint-only.
- Trigger: a function call to `ForEach` whose first argument expression is a member-call chain ending in `sorted`, `filter`, `map`, `compactMap`, or `reversed`.

## Plan

- [x] Failing test
- [x] Implement `NoSortFilterInForEachData`
- [x] Verify test passes; regenerate schema



## Summary of Changes

- LintSyntaxRule on `FunctionCallExprSyntax` checking `ForEach(<call>...)` where `<call>` ends in sorted/filter/map/compactMap/flatMap/reversed/shuffled.
- 5/5 tests passing.
- Schema regenerated.
