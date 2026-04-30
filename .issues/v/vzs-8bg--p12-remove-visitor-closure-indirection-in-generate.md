---
# vzs-8bg
title: 'P12: Remove visitor closure indirection in generated dispatch'
status: ready
type: task
priority: low
created_at: 2026-04-30T15:58:28Z
updated_at: 2026-04-30T15:58:28Z
parent: 6xi-be2
sync:
    github:
        issue_number: "550"
        synced_at: "2026-04-30T16:27:55Z"
---

**Location:** `Sources/SwiftiomaticKit/Syntax/Linter/LintPipeline.swift:16, 28`

`visitor(rule)(node)` is a curried-function indirection. The compiler may not optimize away the per-call `visitor(rule)` closure allocation, especially across module boundaries.

## Potential performance benefit

If the closure isn't being inlined, each visit pays a small heap-or-stack allocation for the curried partial application. Direct `rule.visit(node)` from generated code removes that. Per-node × per-rule overhead is tiny but multiplied by node and rule counts in large files.

## Reason deferred

Generator change — `Pipelines+Generated.swift` would call `rule.visit(node)` directly instead of `visitor(rule)(node)`. Needs P3/P9 design choices to know the final dispatch shape; doing this in isolation creates churn that's overwritten later. Verify with a profile + before/after `-emit-sil` first.
