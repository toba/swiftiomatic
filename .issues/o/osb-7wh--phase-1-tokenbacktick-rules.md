---
# osb-7wh
title: 'Phase 1: Token/backtick rules'
status: completed
type: task
priority: normal
created_at: 2026-04-14T18:36:29Z
updated_at: 2026-04-14T18:36:29Z
parent: c7r-77o
sync:
    github:
        issue_number: "297"
        synced_at: "2026-04-14T18:45:54Z"
---

Rules needing investigation into swift-syntax backtick token representation. All resolved.

- [x] `strongifiedSelf` — Remove backticks around `self` in optional unwrap
- [x] `redundantBackticks` — Remove unnecessary backticks from identifiers
- [x] `redundantPattern` — Remove redundant pattern matching (`case .foo(let _)` → `case .foo(_)`)

## Completion Notes

| Rule | Tests | Key Implementation Detail |
|------|-------|--------------------------|
| `StrongifiedSelf` | 5 | Visits `OptionalBindingConditionSyntax`, checks backticked `self` pattern with `self` initializer |
| `RedundantBackticks` | 38 | Converted lint→format. Token visitor with context-aware checks |
| `RedundantPattern` | 12 | Visits `SwitchCaseItemSyntax`, `MatchingPatternConditionSyntax`, `VariableDeclSyntax` |
