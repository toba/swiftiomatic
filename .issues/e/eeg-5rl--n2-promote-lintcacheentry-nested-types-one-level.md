---
# eeg-5rl
title: 'N2: Promote LintCache.Entry nested types one level'
status: ready
type: task
priority: low
created_at: 2026-04-30T15:59:25Z
updated_at: 2026-04-30T15:59:25Z
parent: 6xi-be2
sync:
    github:
        issue_number: "542"
        synced_at: "2026-04-30T16:27:54Z"
---

**Location:** `Sources/SwiftiomaticKit/Support/LintCache.swift:22, 24, 36`

`LintCache.Entry.Severity`, `.Location`, `.Note` are nested 3-deep (lint rule already flags). Promote them to direct children of `LintCache` (e.g. `LintCache.Severity`, `LintCache.Location`, `LintCache.Note`).

## Potential performance benefit

None — naming only.

## Reason deferred

If we land M2 (drop `Severity` enum entirely, store `Lint` directly), the rename collides with the schema bump. Sequence: M2 first, then promote the remaining `Location` / `Note` types as part of the same cache-schema bump.
