---
# uhz-elr
title: 'N5: Audit lint-flagged IIFE patterns in Context and LintCache'
status: ready
type: task
priority: low
created_at: 2026-04-30T15:59:51Z
updated_at: 2026-04-30T15:59:51Z
parent: 6xi-be2
sync:
    github:
        issue_number: "541"
        synced_at: "2026-04-30T16:27:54Z"
---

**Location:** `Sources/SwiftiomaticKit/Support/Context.swift:1` (likely the `preparedAcronyms` IIFE) and `Sources/SwiftiomaticKit/Support/LintCache.swift:96` (`ruleSetIdentifier`)

The `redundantClosure` lint flagged immediately-invoked closures. Both of the flagged sites use the IIFE shape because the value depends on multi-step setup (sorted/filtered/mapped collections, hash builds). Either suppress lint per-site with intent, or refactor to a regular initializer that returns the same value.

## Potential performance benefit

None — readability / lint cleanliness only.

## Reason deferred

Cosmetic. Mostly a question of which rules to keep loud and which to silence with rationale. Bundle with the next round of lint-flag triage.
