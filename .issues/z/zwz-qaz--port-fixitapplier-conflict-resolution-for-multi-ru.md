---
# zwz-qaz
title: Port FixItApplier conflict resolution for multi-rule corrections
status: completed
type: task
priority: high
created_at: 2026-04-12T23:54:23Z
updated_at: 2026-04-13T00:19:26Z
parent: oad-n72
sync:
    github:
        issue_number: "244"
        synced_at: "2026-04-13T00:25:20Z"
---

Current correction strategy (reverse-sort + sequential `replaceSubrange` in `SwiftSyntaxRule+Correct.swift`) works within a single rule but doesn't handle overlapping corrections between different rules touching the same region.

## Reference

`SwiftIDEUtils/FixItApplier.swift` — ~50-line algorithm that:
- Applies edits in order
- Detects conflicts between overlapping ranges
- Drops conflicting later edits
- Shifts subsequent edit positions by the delta of applied edits

## Tasks

- [x] Port `FixItApplier.apply(edits:to:)` algorithm into SwiftiomaticKit
- [x] Replace reverse-sort approach in `SwiftSyntaxRule+Correct.swift` with conflict-aware application
- [x] Add tests for overlapping corrections from multiple rules on the same file
- [x] Verify existing correction tests still pass


## Summary of Changes

Ported the conflict-aware edit applicator from swift-syntax's `FixItApplier` into `CorrectionApplicator` (package-visible enum). Replaced the old reverse-sort + sequential `replaceSubrange` approach.

Key behaviors:
- Edits sorted by start position (ascending)
- Each applied edit shifts subsequent edits by the byte-count delta
- Overlapping edits are dropped (first-wins)
- Adjacent edits (end == start) are not considered overlapping

Added 8 unit tests covering: non-overlapping edits, overlapping conflict drops, position shifting (shrink + grow), adjacent edits, empty edit skipping, unsorted input, and insertion-inside-replacement.

All existing correctable rule tests pass.
