---
# tkq-7h7
title: 'Infrastructure review: modernize support patterns'
status: in-progress
type: task
priority: normal
created_at: 2026-04-13T01:06:11Z
updated_at: 2026-04-13T01:06:11Z
sync:
    github:
        issue_number: "257"
        synced_at: "2026-04-13T01:09:18Z"
---

Swift review of infrastructure/support code identified these opportunities:

## Medium Priority
- [ ] Remove `@unchecked Sendable` from `Linter`/`CollectedLinter` if Swift 6.2 infers `[any Rule]` as Sendable
- [ ] Remove `@unchecked Sendable` from `RuleSelection` (same reason)
- [ ] Make `Confidence` Comparable O(1) via Int raw values instead of blanket `CaseIterable` `firstIndex` lookup
- [ ] Extract `CurrentRule.$identifier.withValue` boilerplate into a helper

## Low Priority
- [ ] `Documentable` protocol naming (note for future — high churn)
- [ ] Analyzer enrichment loop is sequential (could parallelize with TaskGroup)
- [ ] Analyzer duplicates Linter two-phase collect/validate pattern
