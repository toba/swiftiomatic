---
# 0p9-xlg
title: WarnRecursiveWithObservationTracking
status: completed
type: feature
priority: normal
created_at: 2026-04-30T22:55:07Z
updated_at: 2026-04-30T22:59:51Z
parent: 7h4-72k
sync:
    github:
        issue_number: "584"
        synced_at: "2026-04-30T23:13:22Z"
---

Lint `withObservationTracking { ... } onChange: { ... }` where the `onChange` closure calls the enclosing function — produces an infinite re-tracking loop. Modern code should use the `Observations` AsyncSequence instead.

## Decisions

- Group: `.unsafety`
- Default: `.warn`
- Lint-only.
- Trigger: `withObservationTracking` call. Walk up to the enclosing FunctionDeclSyntax. If the `onChange` closure body contains a call to that function name, emit a finding.

## Plan

- [x] Failing test
- [x] Implement `WarnRecursiveWithObservationTracking`
- [x] Verify test passes; regenerate schema



## Summary of Changes

- LintSyntaxRule. Walks ancestors to find enclosing FunctionDecl, then scans the `onChange` closure for a DeclReferenceExpr matching the function's name.
- 4/4 tests passing.
- Schema regenerated.
