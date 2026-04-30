---
# 7n7-c5z
title: 'P8: Replace Context lazy var rule state with optional let'
status: ready
type: task
priority: normal
created_at: 2026-04-30T15:57:51Z
updated_at: 2026-04-30T15:57:51Z
parent: 6xi-be2
sync:
    github:
        issue_number: "554"
        synced_at: "2026-04-30T16:27:56Z"
---

**Location:** `Sources/SwiftiomaticKit/Support/Context.swift:57-74`

`Context` declares 17 `lazy var` properties for compact-pipeline rule state. Each `lazy` access compiles to a per-property branch + atomic init flag check on every access.

## Potential performance benefit

For hot rules accessed thousands of times per file, the per-property lazy gating adds up. Replacing with optional `let` initialized in `Context.init` only when the matching rule is enabled (using P1's `enabledRules`) gives a single nil check on access and skips initialization for disabled rules entirely.

## Reason deferred

Mechanical refactor across 17 sites; needs P1 already landed (which it now is). Easy follow-up but bundling more state-init logic into `Context.init` warrants its own PR with measurements showing the lazy gating is actually visible in profiles.
