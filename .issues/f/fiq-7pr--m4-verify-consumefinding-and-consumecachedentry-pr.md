---
# fiq-7pr
title: 'M4: Verify consumeFinding and consumeCachedEntry produce byte-identical output'
status: ready
type: task
priority: normal
created_at: 2026-04-30T16:00:16Z
updated_at: 2026-04-30T16:00:16Z
parent: 6xi-be2
sync:
    github:
        issue_number: "553"
        synced_at: "2026-04-30T16:27:56Z"
---

**Location:** `Sources/Swiftiomatic/Utilities/DiagnosticsEngine.swift:121, 179`

The cache replay path (`consumeCachedEntry`) constructs `Diagnostic` with a `category:` argument. The live emission path (`diagnosticMessage(for finding:)`) at `:179` also passes `category:`, but the surrounding plumbing differs slightly (note construction path, message string interpolation). The doc comment claims byte-identical output; need a test that asserts it.

## Potential performance benefit

None — correctness only. A drift here would mean cached vs uncached runs of the same input produce different stderr, breaking CI determinism for `sm lint`.

## Reason deferred

Needs a test fixture: lint a small Swift file twice (once cold, once warm) and diff the stderr byte-for-byte. Easy but distinct from the rest of the cleanup.
