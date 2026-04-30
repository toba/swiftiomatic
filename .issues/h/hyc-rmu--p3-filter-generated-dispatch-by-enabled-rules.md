---
# hyc-rmu
title: 'P3: Filter generated dispatch by enabled rules'
status: ready
type: task
priority: high
created_at: 2026-04-30T15:57:31Z
updated_at: 2026-04-30T15:57:31Z
parent: 6xi-be2
sync:
    github:
        issue_number: "556"
        synced_at: "2026-04-30T16:27:56Z"
---

**Location:** `Sources/SwiftiomaticKit/Generated/Pipelines+Generated.swift`

The generated dispatcher calls `visitIfEnabled(<Rule>.visit, for: node)` for every rule registered against a node kind. Each call still pays a `shouldFormat` check (now O(1) after P1, but still touches `enabledRules.contains` + the per-node selection/mask path) for rules that are off across the whole file. With ~half of rules disabled in any given config, that's a lot of negative dispatch.

## Potential performance benefit

For each disabled rule, eliminates the `shouldFormat` call entirely: per-node cost drops from `(O(1) hash lookup + selection check + mask probe)` to zero per disabled rule. Across a large file with hundreds of nodes × dozens of disabled rules, this is a meaningful cut in the per-node hot path.

## Reason deferred

Requires generator changes — either (a) emit a per-Context active dispatch table keyed by node kind into a precomputed array of `(Rule, visit, visitPost)` closures filtered by `enabledRules` at `LintPipeline.init`, or (b) gate each `visitIfEnabled` call site on a single bool stored in `LintPipeline` (one per rule). Either way the `Generator` executable needs updating to emit the new shape. Builds on P1's `enabledRules` set. Best paired with P9 (typed dispatch table).
