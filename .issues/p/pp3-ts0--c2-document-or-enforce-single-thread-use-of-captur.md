---
# pp3-ts0
title: 'C2: Document or enforce single-thread use of CapturingFindingConsumer'
status: ready
type: task
priority: low
created_at: 2026-04-30T15:59:03Z
updated_at: 2026-04-30T15:59:03Z
parent: 6xi-be2
sync:
    github:
        issue_number: "547"
        synced_at: "2026-04-30T16:27:54Z"
---

**Location:** `Sources/Swiftiomatic/Frontend/LintFrontend.swift:147`

`CapturingFindingConsumer` is a `final class` with mutable `var entries`. Created per-file inside `processFile`, used only synchronously within one `lint(...)` call. Currently safe but undocumented.

## Potential performance benefit

None — correctness only. If a future change hands the consumer to a concurrent worker the data race would be silent.

## Reason deferred

Trivial fix (add a doc comment, or wrap `entries` in a `Mutex<[Entry]>` and make it `Sendable`). Bundling it with C1 makes more sense than landing alone.
