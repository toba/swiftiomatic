---
# eeg-5rl
title: 'N2: Promote LintCache.Entry nested types one level'
status: completed
type: task
priority: low
created_at: 2026-04-30T15:59:25Z
updated_at: 2026-04-30T19:59:16Z
parent: 6xi-be2
sync:
    github:
        issue_number: "542"
        synced_at: "2026-04-30T20:01:23Z"
---

**Location:** `Sources/SwiftiomaticKit/Support/LintCache.swift:22, 24, 36`

`LintCache.Entry.Severity`, `.Location`, `.Note` are nested 3-deep (lint rule already flags). Promote them to direct children of `LintCache` (e.g. `LintCache.Severity`, `LintCache.Location`, `LintCache.Note`).

## Potential performance benefit

None — naming only.

## Reason deferred

If we land M2 (drop `Severity` enum entirely, store `Lint` directly), the rename collides with the schema bump. Sequence: M2 first, then promote the remaining `Location` / `Note` types as part of the same cache-schema bump.



## Summary of Changes

`LintCache.Entry.Location` and `LintCache.Entry.Note` promoted to `LintCache.Location` and `LintCache.Note` (one nesting level instead of three). The `Entry` struct now references the top-level types.

Updated:
- `Sources/SwiftiomaticKit/Support/LintCache.swift`: types defined directly under `LintCache`; the `extension LintCache.Entry.Location` block becomes `extension LintCache.Location`.
- `Sources/Swiftiomatic/Frontend/LintFrontend.swift` (`CapturingFindingConsumer`): `LintCache.Entry.Location.init` → `LintCache.Location.init`, `LintCache.Entry.Note(...)` → `LintCache.Note(...)`.

JSON shape unchanged — Swift type nesting doesn't affect the encoded keys. Existing cache records continue to decode. Bundled with M2 so a single change touches both shape adjustments.
