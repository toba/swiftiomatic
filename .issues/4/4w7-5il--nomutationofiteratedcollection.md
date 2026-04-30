---
# 4w7-5il
title: NoMutationOfIteratedCollection
status: completed
type: feature
priority: normal
created_at: 2026-04-30T21:13:08Z
updated_at: 2026-04-30T21:17:52Z
parent: 7h4-72k
sync:
    github:
        issue_number: "579"
        synced_at: "2026-04-30T23:13:22Z"
---

Lint mutating-call patterns where the loop iterates a collection and the body mutates it: `array.remove(at:)`/`insert`/`append`/`removeAll`/`removeFirst`/`removeLast` on the same name as the for-in subject.

## Decisions

- Group: `.unsafety`
- Default: `.warn`
- Lint-only.
- Trigger: `for x in NAME { ... NAME.<mut>(...) ... }` where `NAME` is a bare identifier or member-access; mutating methods are a fixed list.

## Plan

- [x] Failing test
- [x] Implement `NoMutationOfIteratedCollection`
- [x] Verify test passes; regenerate schema



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Unsafety/NoMutationOfIteratedCollection.swift` — LintSyntaxRule on `ForStmtSyntax`. Mutator names: append, insert, remove, removeAll, removeFirst, removeLast, removeSubrange, popLast, popFirst, swapAt, reverse, sort, shuffle, replaceSubrange. Receiver match by `trimmedDescription`.
- 6/6 tests passing.
- Schema regenerated.
