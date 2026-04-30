---
# bsk-ooc
title: PreferEmptyCollectionForArrayArgs
status: completed
type: feature
priority: normal
created_at: 2026-04-30T20:45:47Z
updated_at: 2026-04-30T20:50:22Z
parent: 7h4-72k
sync:
    github:
        issue_number: "576"
        synced_at: "2026-04-30T23:13:20Z"
---

Lint `[]` and `[x]` array literals passed as function-call arguments — suggest `EmptyCollection()` / `CollectionOfOne(x)`.

## Decisions

- Group: `.literals`
- Default: `.no` (opt-in — false-positive risk without type info)
- Lint-only (no rewrite — needs type info to be safe)
- Scope: any `ArrayExprSyntax` of 0 or 1 element appearing as a function-call argument

## Plan

- [x] Failing test
- [x] Implement `PreferEmptyCollectionForArrayArgs` (LintSyntaxRule, group .literals, default lint=no)
- [x] Verify test passes; regenerate schema



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Literals/PreferEmptyCollectionForArrayArgs.swift` — opt-in LintSyntaxRule (`defaultValue: .no`).
- 6/6 tests passing.
- Schema regenerated.
