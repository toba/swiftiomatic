---
# tkq-7h7
title: 'Infrastructure review: modernize support patterns'
status: completed
type: task
priority: normal
created_at: 2026-04-13T01:06:11Z
updated_at: 2026-04-13T01:15:04Z
sync:
    github:
        issue_number: "257"
        synced_at: "2026-04-13T01:16:46Z"
---

Swift review of infrastructure/support code identified these opportunities:

## Medium Priority
- [x] Remove `@unchecked Sendable` from `Linter`/`CollectedLinter` if Swift 6.2 infers `[any Rule]` as Sendable
- [x] Remove `@unchecked Sendable` from `RuleSelection` (same reason)
- [x] Make `Confidence` Comparable O(1) via explicit `order` property (kept String raw value for YAML compat)
- [x] Extract `CurrentRule.$identifier.withValue` boilerplate into `CurrentRule.withContext(of:)` helper

## Low Priority
- [ ] `Documentable` protocol naming (deferred — high churn, low value)
- [ ] Analyzer enrichment loop is sequential (deferred — SourceKit serializes internally)
- [ ] Analyzer duplicates Linter two-phase pattern (deferred — separate orchestration needs)


## Summary of Changes

- Removed `@unchecked Sendable` from `Linter`, `CollectedLinter`, and `RuleSelection` — Swift 6.2 correctly infers `[any Rule]` as Sendable when `Rule: Sendable`
- Replaced blanket `CaseIterable & Comparable` extension (O(n) `firstIndex` per comparison) with explicit O(1) `Comparable` on `Confidence` and `AccessControlLevel`
- Added `CurrentRule.withContext(of:_:)` helper (sync + async overloads) replacing 9 `CurrentRule.$identifier.withValue(type(of: rule).identifier)` call sites
- All changes: build succeeds, RuleExampleTests pass, Configuration tests pass
