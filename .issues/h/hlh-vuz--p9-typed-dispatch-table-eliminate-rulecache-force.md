---
# hlh-vuz
title: 'P9: Typed dispatch table — eliminate ruleCache force cast'
status: ready
type: task
priority: high
created_at: 2026-04-30T15:57:59Z
updated_at: 2026-04-30T15:57:59Z
parent: 6xi-be2
sync:
    github:
        issue_number: "557"
        synced_at: "2026-04-30T16:27:56Z"
---

**Location:** `Sources/SwiftiomaticKit/Syntax/Linter/LintPipeline.swift:61-67`

`LintPipeline.rule(_:)` does `ruleCache[id] as! R` on every visit (also flagged by `noForceCast`). `ruleCache` is `[ObjectIdentifier: any SyntaxRule]` — every access is an existential dispatch + force cast.

## Potential performance benefit

Replaces a hot-path `Dictionary` lookup + existential dispatch + unconditional force cast with a single array index. Across hundreds of nodes × dozens of enabled rules per file, the savings on the per-visit hot path are measurable.

## Reason deferred

Requires generator changes: emit a per-rule integer index, allocate a closed array of rule instances (or lazily-constructed slots) at `LintPipeline.init`, and have generated dispatch use the integer index. Resolves N4 (force cast) as a side effect. Pairs with P3.
