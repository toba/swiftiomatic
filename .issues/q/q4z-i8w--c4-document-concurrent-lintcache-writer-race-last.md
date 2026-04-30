---
# q4z-i8w
title: 'C4: Document concurrent LintCache writer race (last-writer-wins)'
status: ready
type: task
priority: low
created_at: 2026-04-30T15:59:09Z
updated_at: 2026-04-30T15:59:09Z
parent: 6xi-be2
sync:
    github:
        issue_number: "548"
        synced_at: "2026-04-30T16:27:55Z"
---

**Location:** `Sources/SwiftiomaticKit/Support/LintCache.swift` (module docs)

Two concurrent `sm lint` invocations on overlapping files can race on the same cache record path. `.atomic` write makes the final state consistent (last-writer-wins) but isn't documented anywhere.

## Potential performance benefit

None — documentation-only.

## Reason deferred

Trivial. Worth folding into a broader `LintCache` docs pass (alongside C2 and N2).
