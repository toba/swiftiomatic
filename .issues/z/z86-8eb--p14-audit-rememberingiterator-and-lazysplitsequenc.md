---
# z86-8eb
title: 'P14: Audit RememberingIterator and LazySplitSequence for hot-path use'
status: ready
type: task
priority: low
created_at: 2026-04-30T15:58:46Z
updated_at: 2026-04-30T15:58:46Z
parent: 6xi-be2
sync:
    github:
        issue_number: "543"
        synced_at: "2026-04-30T16:27:54Z"
---

**Location:** `Sources/SwiftiomaticKit/Support/` (the support utilities)

`RememberingIterator` and `LazySplitSequence` are general utilities. The review flagged that we should confirm they aren't used inside the per-rule visit hot path; if so, audit for allocations (e.g. closure captures, intermediate `Array` materialization).

## Potential performance benefit

Unknown until measured. If a hot rule iterates a tokenized doc-comment via `LazySplitSequence` per visit, ARC traffic + allocations could show in a profile.

## Reason deferred

Needs profiling first to determine whether either utility is even on the hot path. No code change yet — gating action is `grep + Instruments`.
