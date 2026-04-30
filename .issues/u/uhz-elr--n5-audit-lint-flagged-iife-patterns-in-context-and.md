---
# uhz-elr
title: 'N5: Audit lint-flagged IIFE patterns in Context and LintCache'
status: completed
type: task
priority: low
created_at: 2026-04-30T15:59:51Z
updated_at: 2026-04-30T19:49:19Z
parent: 6xi-be2
sync:
    github:
        issue_number: "541"
        synced_at: "2026-04-30T20:01:23Z"
---

**Location:** `Sources/SwiftiomaticKit/Support/Context.swift:1` (likely the `preparedAcronyms` IIFE) and `Sources/SwiftiomaticKit/Support/LintCache.swift:96` (`ruleSetIdentifier`)

The `redundantClosure` lint flagged immediately-invoked closures. Both of the flagged sites use the IIFE shape because the value depends on multi-step setup (sorted/filtered/mapped collections, hash builds). Either suppress lint per-site with intent, or refactor to a regular initializer that returns the same value.

## Potential performance benefit

None — readability / lint cleanliness only.

## Reason deferred

Cosmetic. Mostly a question of which rules to keep loud and which to silence with rationale. Bundle with the next round of lint-flag triage.



## Summary of Changes

Audited the two flagged sites:

1. **`Context.preparedAcronyms`** (`Sources/SwiftiomaticKit/Support/Context.swift`): removed the IIFE wrapper. The single-expression chain (`filter().sorted().map()`) reads cleanly as a direct `lazy var x: T = expr` initializer. Same behavior, simpler shape, no longer trips `RedundantClosure`.

2. **`LintCache.ruleSetIdentifier`** (`Sources/SwiftiomaticKit/Support/LintCache.swift:96`): kept as IIFE. The closure body is multi-statement (`var hasher`, `hasher.update` … sequenced operations on a mutable hasher), so `RedundantClosure.transform` short-circuits at the `firstAndOnly` check (RedundantClosure.swift:35). Not flagged in practice.
