---
# 74p-eol
title: 'M2: Store Lint directly in LintCache.Entry — drop parallel Severity enum'
status: completed
type: task
priority: normal
created_at: 2026-04-30T16:00:07Z
updated_at: 2026-04-30T19:59:08Z
parent: 6xi-be2
sync:
    github:
        issue_number: "540"
        synced_at: "2026-04-30T20:01:24Z"
---

**Location:** `Sources/SwiftiomaticKit/Support/LintCache.swift` (`Entry.Severity`, `asLint`) and `Sources/Swiftiomatic/Utilities/DiagnosticsEngine.swift:121-126`

The cache schema today has its own `LintCache.Entry.Severity` (`.error|.warn|.no`) plus translation extensions in two places. `Lint` (the live finding-severity type) is already `Codable`. Storing `Lint` directly drops the duplicate enum and one direction of translation.

## Potential performance benefit

Marginal — fewer switch statements per cached finding emit. Real value is correctness: removes a class of "forgot to update both translations" bugs.

## Reason deferred

Bumps `Record.currentVersion` from 1 to 2 — invalidates every existing on-disk cache. Acceptable, but pair with N2 (promote nested types) so the cache is invalidated only once. Needs a unit test for round-trip across the new schema.



## Summary of Changes

`LintCache.Entry.severity` now stores `Lint` directly. The parallel `LintCache.Entry.Severity` enum and the `asLint` / `init(_ severity: Lint)` translation extension are removed.

- `Sources/SwiftiomaticKit/Support/LintCache.swift`: dropped the nested `Severity` enum; `Entry.severity` is now `Lint`.
- `Sources/Swiftiomatic/Frontend/LintFrontend.swift` (`CapturingFindingConsumer`): drops the `LintCache.Entry.Severity(finding.severity)` wrapper — passes `finding.severity` (which is already `Lint`) directly.
- `Sources/Swiftiomatic/Utilities/DiagnosticsEngine.swift` (`consumeCachedEntry`): switch over `Lint` cases (`.error / .warn / .no`) — same case names, no semantic change.

**On-disk schema not bumped.** `Lint` and the prior `Entry.Severity` both Codable-encode as the same string raw values (`"error"`, `"warn"`, `"no"`), so cache records written under v1 decode unchanged. Verified by a new test `entryDecodesV1SeverityRawStrings` that decodes a v1-shaped JSON blob into the new `Entry` type.

Tests added in `Tests/SwiftiomaticTests/Core/LintCacheTests.swift`:
- `entrySeveritySerializesAsRawString` — pins the JSON shape (`"severity":"warn"`).
- `entryRoundTripsThroughJSON` — encode → decode equality.
- `entryDecodesV1SeverityRawStrings` — v1 forward-compat.
