---
# 74p-eol
title: 'M2: Store Lint directly in LintCache.Entry — drop parallel Severity enum'
status: ready
type: task
priority: normal
created_at: 2026-04-30T16:00:07Z
updated_at: 2026-04-30T16:00:07Z
parent: 6xi-be2
sync:
    github:
        issue_number: "540"
        synced_at: "2026-04-30T16:27:54Z"
---

**Location:** `Sources/SwiftiomaticKit/Support/LintCache.swift` (`Entry.Severity`, `asLint`) and `Sources/Swiftiomatic/Utilities/DiagnosticsEngine.swift:121-126`

The cache schema today has its own `LintCache.Entry.Severity` (`.error|.warn|.no`) plus translation extensions in two places. `Lint` (the live finding-severity type) is already `Codable`. Storing `Lint` directly drops the duplicate enum and one direction of translation.

## Potential performance benefit

Marginal — fewer switch statements per cached finding emit. Real value is correctness: removes a class of "forgot to update both translations" bugs.

## Reason deferred

Bumps `Record.currentVersion` from 1 to 2 — invalidates every existing on-disk cache. Acceptable, but pair with N2 (promote nested types) so the cache is invalidated only once. Needs a unit test for round-trip across the new schema.
