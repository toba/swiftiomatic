---
# pp3-ts0
title: 'C2: Document or enforce single-thread use of CapturingFindingConsumer'
status: completed
type: task
priority: low
created_at: 2026-04-30T15:59:03Z
updated_at: 2026-04-30T19:47:29Z
parent: 6xi-be2
sync:
    github:
        issue_number: "547"
        synced_at: "2026-04-30T20:01:24Z"
---

**Location:** `Sources/Swiftiomatic/Frontend/LintFrontend.swift:147`

`CapturingFindingConsumer` is a `final class` with mutable `var entries`. Created per-file inside `processFile`, used only synchronously within one `lint(...)` call. Currently safe but undocumented.

## Potential performance benefit

None — correctness only. If a future change hands the consumer to a concurrent worker the data race would be silent.

## Reason deferred

Trivial fix (add a doc comment, or wrap `entries` in a `Mutex<[Entry]>` and make it `Sendable`). Bundling it with C1 makes more sense than landing alone.



## Summary of Changes

Added a doc comment on `CapturingFindingConsumer` (`Sources/Swiftiomatic/Frontend/LintFrontend.swift`) documenting the single-thread invariant, why `entries` is not synchronized, and the migration path (Mutex + Sendable) if a future change hands the consumer to a concurrent worker.
