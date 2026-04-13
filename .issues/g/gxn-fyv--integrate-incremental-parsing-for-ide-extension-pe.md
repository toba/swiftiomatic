---
# gxn-fyv
title: Integrate incremental parsing for IDE extension performance
status: completed
type: feature
priority: low
created_at: 2026-04-12T23:54:23Z
updated_at: 2026-04-13T00:47:54Z
parent: oad-n72
sync:
    github:
        issue_number: "249"
        synced_at: "2026-04-13T00:55:42Z"
---

swift-syntax supports incremental reparsing that reuses unchanged subtrees when source edits are small. Currently `SwiftSource.syntaxTree` caches the full parse per file — incremental reparsing would be faster for repeated lint-on-type in the editor extension.

## Reference

`SwiftParser/IncrementalParseTransition.swift`:
- `IncrementalParseTransition` — tracks previous parse result + edits
- `ConcurrentEdits` — non-overlapping source edits
- `IncrementalParseLookup` — O(1) lookups for reusable nodes by position and kind
- Callback mechanism to track which nodes were reused

## Tasks

- [x] Investigate `IncrementalParseTransition` API surface
- [x] Extend `SwiftSource` to accept previous parse result + edits
- [ ] Measure parse time improvement on typical edit-then-lint cycles (deferred — needs IDE extension integration)
- [ ] Integrate with Xcode Source Editor Extension if measurable benefit (deferred)


## Summary of Changes

Added incremental parsing infrastructure:

- `incrementalParseResultCache` stores `IncrementalParseResult` (tree + lookaheadRanges) alongside the existing `syntaxTreeCache`
- `SwiftSource.reparseIncrementally(newSource:edits:)` accepts `ConcurrentEdits` and re-parses using `IncrementalParseTransition`, reusing unchanged subtrees
- The method updates the file contents, stores the new parse result, and invalidates dependent caches (locationConverter, commands, etc.)
- `SwiftSource.incrementalParseResult` exposes the cached result for constructing transitions

The IDE extension can call `reparseIncrementally` instead of invalidating and re-parsing from scratch. Benchmarking and extension integration deferred.
