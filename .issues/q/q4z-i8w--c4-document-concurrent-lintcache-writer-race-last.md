---
# q4z-i8w
title: 'C4: Document concurrent LintCache writer race (last-writer-wins)'
status: completed
type: task
priority: low
created_at: 2026-04-30T15:59:09Z
updated_at: 2026-04-30T19:47:34Z
parent: 6xi-be2
sync:
    github:
        issue_number: "548"
        synced_at: "2026-04-30T20:01:23Z"
---

**Location:** `Sources/SwiftiomaticKit/Support/LintCache.swift` (module docs)

Two concurrent `sm lint` invocations on overlapping files can race on the same cache record path. `.atomic` write makes the final state consistent (last-writer-wins) but isn't documented anywhere.

## Potential performance benefit

None — documentation-only.

## Reason deferred

Trivial. Worth folding into a broader `LintCache` docs pass (alongside C2 and N2).



## Summary of Changes

Added a doc paragraph to the `LintCache` type-level comment in `Sources/SwiftiomaticKit/Support/LintCache.swift` documenting the concurrent-writer race: two `sm lint` processes can land on the same record path; `.atomic` write-then-rename ensures readers see a complete record (never torn); the last rename wins; both inputs are equivalent by construction (same content hash + fingerprint ⇒ same findings), so the surviving record is always valid. Notes that there is no inter-process lock — future consumers should not assume one.
