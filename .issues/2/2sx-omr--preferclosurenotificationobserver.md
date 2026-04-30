---
# 2sx-omr
title: PreferClosureNotificationObserver
status: completed
type: feature
priority: normal
created_at: 2026-04-30T21:41:39Z
updated_at: 2026-04-30T21:46:13Z
parent: 7h4-72k
sync:
    github:
        issue_number: "567"
        synced_at: "2026-04-30T23:13:20Z"
---

Lint selector-based `NotificationCenter.addObserver(self, selector:, name:, object:)` — prefer closure-based `addObserver(forName:object:queue:using:)`. Selector-based observers require @objc handlers and cause cleanup pitfalls.

## Decisions

- Group: `.idioms`
- Default: `.warn`
- Lint-only — rewrite would need to relocate the @objc handler.
- Trigger: a method call `<recv>.addObserver(...)` whose first argument is `self` and whose label list begins with no label (self), then `selector:`, `name:`, `object:`.

## Plan

- [x] Failing test
- [x] Implement `PreferClosureNotificationObserver`
- [x] Verify test passes; regenerate schema



## Summary of Changes

- LintSyntaxRule. Matches `addObserver(_, selector:, name:, object:)` by checking the 4-argument label tuple.
- 3/3 tests passing.
- Schema regenerated.
