---
# 19s-cld
title: 'C1: Drop @unchecked Sendable on LintFrontend (and parent Frontend)'
status: ready
type: task
priority: low
created_at: 2026-04-30T15:58:54Z
updated_at: 2026-04-30T15:58:54Z
parent: 6xi-be2
sync:
    github:
        issue_number: "558"
        synced_at: "2026-04-30T16:27:57Z"
---

**Location:** `Sources/Swiftiomatic/Frontend/LintFrontend.swift:19` (and `Frontend.swift:19`)

`LintFrontend` declares `@unchecked Sendable`. Its only stored field is `let cache: LintCache?` (already `Sendable`). The `@unchecked` looks vestigial — but the parent `Frontend` is also `@unchecked Sendable`, so the child has to be too.

## Potential performance benefit

None — this is a correctness/code-hygiene cleanup (SE-0470). Reduces blast radius of future Sendable bugs.

## Reason deferred

Has to be done as a coordinated migration with `Frontend` (which has `var debugOptions` etc.). Needs an audit of `Frontend`'s mutable state to confirm safe-by-construction Sendable conformance (or proper isolation). Not a perf win; low priority.
