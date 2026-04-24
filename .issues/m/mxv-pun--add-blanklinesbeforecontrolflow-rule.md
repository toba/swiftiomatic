---
# mxv-pun
title: Add BlankLinesBeforeControlFlow rule
status: completed
type: feature
priority: normal
created_at: 2026-04-24T01:44:01Z
updated_at: 2026-04-24T01:56:05Z
sync:
    github:
        issue_number: "364"
        synced_at: "2026-04-24T02:26:01Z"
---

Add a blank line before multi-line control flow statements (`for`, `while`, `repeat`, `if`, `switch`, `do`, `defer`) when preceded by another statement in the same scope.

- [x] Create rule file
- [x] Create test file
- [x] Build and verify


## Summary of Changes

Added `BlankLinesBeforeControlFlow` rule (key: `beforeControlFlow`, group: `blankLines`) that inserts a blank line before multi-line control flow statements (`for`, `while`, `repeat`, `if`, `switch`, `do`, `defer`) when preceded by another statement in the same scope. Defaults to off. 12 tests covering all control flow types, single-line exclusion, nesting, and no-op cases.
