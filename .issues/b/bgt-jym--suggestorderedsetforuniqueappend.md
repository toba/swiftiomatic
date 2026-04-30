---
# bgt-jym
title: SuggestOrderedSetForUniqueAppend
status: completed
type: feature
priority: normal
created_at: 2026-04-30T20:58:09Z
updated_at: 2026-04-30T21:02:56Z
parent: 7h4-72k
sync:
    github:
        issue_number: "569"
        synced_at: "2026-04-30T23:13:20Z"
---

Lint the `if !array.contains(x) { array.append(x) }` pattern. Suggest `OrderedSet` (swift-collections) as a more efficient unique-preserving collection.

## Decisions

- Group: `.idioms`
- Default: `.warn`
- Lint-only — rewrite would change the variable's type (Array → OrderedSet) which is unsafe at the rule level.

## Plan

- [x] Failing test
- [x] Implement `SuggestOrderedSetForUniqueAppend`
- [x] Verify test passes; regenerate schema



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Idioms/SuggestOrderedSetForUniqueAppend.swift` — LintSyntaxRule. Matches `if !X.contains(y) { X.append(y) }` with single-condition guard, single-statement body, identical receiver, identical argument (compared via `trimmedDescription`).
- 6/6 tests passing.
- Schema regenerated.
