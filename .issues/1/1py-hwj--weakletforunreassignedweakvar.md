---
# 1py-hwj
title: WeakLetForUnreassignedWeakVar
status: completed
type: feature
priority: normal
created_at: 2026-04-30T20:28:46Z
updated_at: 2026-04-30T20:33:55Z
parent: 7h4-72k
sync:
    github:
        issue_number: "578"
        synced_at: "2026-04-30T23:13:22Z"
---

Lint `weak var` stored properties on classes/actors that are never reassigned (SE-0481 → `weak let`).

## Decisions

- Group: `.declarations`
- Default: `.warn` (lint-only — no autofix)
- Scope: stored properties on `class`/`actor` declarations only
- Implementation: `LintSyntaxRule`. A property is "reassigned" if any descendant of the enclosing class/actor body contains `<name> = …` or `self.<name> = …` outside of an initializer for that exact declaration. Init assignments don't count (let allows init-time assignment).

## Plan

- [x] Failing test
- [x] Implement `WeakLetForUnreassignedWeakVar` (LintSyntaxRule, group .declarations, default warn)
- [x] Verify test passes; regenerate schema



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Declarations/WeakLetForUnreassignedWeakVar.swift` — LintSyntaxRule visiting class/actor decls; per-property assignment scan via `AssignmentCollector`, skipping `init` members.
- `Tests/SwiftiomaticTests/Rules/WeakLetForUnreassignedWeakVarTests.swift` — 6/6 passing.
- Schema regenerated; `weakLetForUnreassignedWeakVar` entry present.
