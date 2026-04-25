---
# y5m-pr3
title: Misc small perf nits in Layout, Schema, Rules
status: completed
type: task
priority: low
created_at: 2026-04-25T20:42:07Z
updated_at: 2026-04-25T22:21:41Z
parent: 0ra-lks
sync:
    github:
        issue_number: "427"
        synced_at: "2026-04-25T22:35:10Z"
---

Bundled small perf nits — each is a 1–3 line change.

## Findings

- [x] `LayoutCoordinator` `.count - 1` indexing audit: all 3 sites are mutations (assigning into `.contributesBlockIndent` / `.contributesBlockIndent` / `.contributesBreakingBehavior`), so per the issue's own criterion `count - 1` is the proper index. No change.
- [ ] `currentIndentation` caching: deferred — adding a cache requires lifecycle tracking across many mutation sites and the risk/reward isn't justified for a low-priority pass. Left as future work.
- [x] `splitScopingBeforeTokens(_:)` now returns `ArraySlice<Token>` instead of `[Token]`; eliminates two array allocations per call. Caller uses `.forEach(appendToken)` which works unchanged.
- [x] `sortMarkedRegions` now operates on `ArraySlice<Element>` directly instead of `Array(items[...])`.
- [x] Reordered: `originalNames` now computed once before the `sorted` allocation. (Note: `originalNames` and `sortedNames` map different inputs, so they cannot share a single `compactMap` call as the issue suggested.)
- [x] Verified: `resolvedName(of:)` already uses `.map { ... }.joined()` (no `+=`); the issue description was based on an older revision. No change.
- [x] `JSONPointer.path` now does a single character-by-character walk emitting `~0` / `~1` escapes, eliminating two `replacingOccurrences` passes per component.
- [ ] `RefResolver.store` caching: `validateSchema(...)` is called once per `Doctor` invocation against `ConfigurationSchema.schema`; the rebuild cost is one-shot, so caching adds complexity for no measurable win. Deferred.
- [x] `StderrDiagnosticPrinter.printDiagnostic` now builds the full ANSI-formatted message string outside the lock and writes once under the lock.


## Summary of Changes

- `splitScopingBeforeTokens(_:)` returns `ArraySlice<Token>` (drops 2 array allocations per call).
- `SortDeclarations.sortMarkedRegions` operates on `ArraySlice` directly.
- `JSONPointer.path` single-pass character walk replaces 2 `replacingOccurrences` per component.
- `StderrDiagnosticPrinter.printDiagnostic` builds the formatted message outside the lock and writes once under it.
- 3 findings reviewed and either confirmed already-correct (`LayoutCoordinator` `count - 1` is for mutation; `RequireSuperCall.resolvedName` already uses `.joined()`) or deferred as future work (`currentIndentation` cache; `RefResolver.store` cache).
- All 2795 tests pass.
