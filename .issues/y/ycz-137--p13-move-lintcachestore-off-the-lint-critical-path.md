---
# ycz-137
title: 'P13: Move LintCache.store off the lint critical path'
status: ready
type: task
priority: normal
created_at: 2026-04-30T15:58:38Z
updated_at: 2026-04-30T15:58:38Z
parent: 6xi-be2
sync:
    github:
        issue_number: "555"
        synced_at: "2026-04-30T16:27:56Z"
---

**Location:** `Sources/Swiftiomatic/Frontend/LintFrontend.swift:104` → `Sources/SwiftiomaticKit/Support/LintCache.swift` (`store`)

After lint completes for a file, `store` performs a JSON encode + atomic file write inline, blocking the per-file worker thread. Across hundreds of files in parallel, every worker is doing synchronous I/O after every lint.

## Potential performance benefit

When `--parallel` is on, each worker that finishes a clean file blocks on disk write before picking up the next file. Moving writes to a single background actor (or batching one write per N files / at end-of-run) frees workers to immediately start the next file. The benefit scales with miss-rate × file-count and is most visible on full first runs.

## Reason deferred

Needs a small architecture: a Sendable write queue (`AsyncStream<WriteRequest>` consumed by a detached task, or a simple actor). Has to handle process exit cleanly so pending writes flush. Unit tests for ordering and crash-safety required.
