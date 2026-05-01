---
# 2zx-6n8
title: Review high-relevance upstream SwiftFormat changes
status: completed
type: task
priority: normal
created_at: 2026-05-01T15:35:08Z
updated_at: 2026-05-01T15:49:42Z
sync:
    github:
        issue_number: "600"
        synced_at: "2026-05-01T16:32:29Z"
---

Review HIGH-relevance commits from `nicklockwood/SwiftFormat` (since `397309e7`, last checked 2026-04-26) for analogous bugs/edge cases in Swiftiomatic rules.

## Commits to review

- [x] `8b998f0` — `redundantStaticSelf` false positive in closures/nested funcs. **CONFIRMED + FIXED** in `RedundantStaticSelf.isInStaticContext` — track a `crossedFunctionBoundary` flag while walking up; if set when we hit the static decl, return false. Added 3 tests covering closure-in-static-func, mixed direct+closure, and nested-func-in-static-func. Existing `redundantStaticSelfInNestedFunction` test renamed to `preserveSelfInNestedFunctionInsideStaticFunc` and inverted (was asserting the buggy behavior).
- [x] `a9ec7c3` — `redundantSelf` crash on switch in if-let chain. **NOT APPLICABLE** — fix was in SwiftFormat's hand-rolled token parser (`ParsingHelpers.swift`). Swiftiomatic uses swift-syntax which parses if-let-with-switch-expression correctly via the AST.
- [x] `69672c5` — `redundantEquatable` and non-Equatable property types. **CONFIRMED + FIXED** in `RedundantEquatable` (broader than upstream). We had no type-aware filter at all — only name matching. Added `hasNonEquatableStoredProperty` + `isKnownNonEquatableType` covering metatypes (`T.Type`, `Any.Type`), `AnyClass`, `Any`, tuples (≥2 elements), and function types. Added 4 tests.
- [x] `1e0aaaa` — unsafe keyword dot-spacing. **NOT APPLICABLE** — Swiftiomatic has no `spaceAroundOperators` rule; spacing around member access is handled by the pretty printer (token stream), which doesn't have the upstream's identifier/contextual-keyword ambiguity bug.
- [x] `3e5bdf2` — config-file parse race. **CONFIRMED + FIXED** in `ConfigurationLoader.configuration(at:)`. Same pattern: separate read-lock then write-lock around an unguarded parse, so concurrent callers for the same key duplicated work. Now the load happens inside the `Mutex.withLock` closure. (Cannot deadlock — `Configuration(contentsOf:)` does not recurse into the cache.)
- [x] `a5fa7a6` — 0.61.1 release. The changelog is just the four fixes already covered above.

## Files of interest

- `Sources/FormattingHelpers.swift`
- `Sources/ParsingHelpers.swift`
- `Sources/Rules/RedundantEquatable.swift`
- `Sources/Rules/SpaceAroundOperators.swift`
- `Sources/Rules/PreferFinalClasses.swift`
- `Sources/SwiftFormat.swift`

Reference clone: `~/Developer/swiftiomatic-ref/` (add SwiftFormat checkout if missing).



## Summary of Changes

**Fixed (3):**
- `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantStaticSelf.swift` — preserve `Self.` across closure / nested-function boundaries.
- `Sources/SwiftiomaticKit/Rules/Redundancies/RedundantEquatable.swift` — skip the rewrite when any stored property has a known non-Equatable type (metatypes, `AnyClass`, `Any`, tuples, function types).
- `Sources/Swiftiomatic/Frontend/ConfigurationLoader.swift` — hold the cache mutex across the file load so concurrent callers don't duplicate parse work.

**Tests added (7):** 4 in `RedundantEquatableTests`, 3 in `RedundantStaticSelfTests`. One existing test (`redundantStaticSelfInNestedFunction`) was inverted to match the corrected behavior.

**Verified:** filtered tests pass (37/37); full suite passes (3151/3151).

**Not applicable (2):** the `redundantSelf` switch-in-if-let crash and the `unsafe` dot-spacing fix are both swift-format token-parser bugs that don't translate — Swiftiomatic uses swift-syntax for parsing and the pretty printer for spacing.
