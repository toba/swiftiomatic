---
# ryf-8s1
title: 'N4: Eliminate force cast in LintPipeline.rule(_:)'
status: ready
type: task
priority: low
created_at: 2026-04-30T15:59:43Z
updated_at: 2026-04-30T15:59:43Z
parent: 6xi-be2
blocked_by:
    - hlh-vuz
sync:
    github:
        issue_number: "551"
        synced_at: "2026-04-30T16:27:55Z"
---

**Location:** `Sources/SwiftiomaticKit/Syntax/Linter/LintPipeline.swift:63`

`return cachedRule as! R` — flagged by the `noForceCast` lint rule. Currently safe because of the symmetric write at `:65`, but unconditional force casts are an anti-pattern.

## Potential performance benefit

None directly (force cast is cheap). But removing it falls out of P9 (typed dispatch table) for free, so this isn't standalone work.

## Reason deferred

Subsumed by P9 (`hlh-vuz`). Closing this issue without P9 would mean a defensive precondition + comment, which doesn't add much. Tracked here so it's not lost.
