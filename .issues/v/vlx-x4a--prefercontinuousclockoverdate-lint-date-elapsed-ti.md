---
# vlx-x4a
title: 'PreferContinuousClockOverDate: lint Date() elapsed-time pattern'
status: completed
type: feature
priority: normal
created_at: 2026-04-30T20:53:23Z
updated_at: 2026-04-30T20:57:58Z
parent: 7h4-72k
sync:
    github:
        issue_number: "574"
        synced_at: "2026-04-30T23:13:20Z"
---

Lint `Date().timeIntervalSince(_:)` and `Date().timeIntervalSinceNow` — these are elapsed-time measurements that should use `ContinuousClock.now` + `duration(to:)`.

## Decisions

- Group: `.idioms` (modernization, sibling of PreferContains/PreferAllSatisfy)
- Default: `.warn`
- Lint-only — autofix requires also rewriting the start-time `let start = Date()` site which is out of single-node reach.

## Plan

- [x] Failing test
- [x] Implement `PreferContinuousClockOverDate`
- [x] Verify test passes; regenerate schema



## Summary of Changes

- `Sources/SwiftiomaticKit/Rules/Idioms/PreferContinuousClockOverDate.swift` — LintSyntaxRule. Detects `Date().timeIntervalSince(_:)` and `Date().timeIntervalSinceNow`. Bails on `Date(args)`.
- 5/5 tests passing.
- Schema regenerated.
