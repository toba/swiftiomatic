---
# u1n-nyy
title: Rename `compoundCaseStatements` to `wrapCompoundCaseItems`
status: completed
type: task
priority: normal
created_at: 2026-04-24T22:02:11Z
updated_at: 2026-04-24T22:04:19Z
sync:
    github:
        issue_number: "382"
        synced_at: "2026-04-24T22:30:44Z"
---

Rename config key and update references. Rule stays in `.wrap` group.

- [x] Update key override in rule source
- [x] Update test references
- [x] Update all references
- [x] Regenerate schema
- [x] Build and test


## Summary of Changes

Renamed class `WrapCompoundCaseStatements` → `WrapCompoundCaseItems`, file, and config key `compoundCaseStatements` → `wrapCompoundCaseItems`. Updated test and issue references. All 7 tests pass.
