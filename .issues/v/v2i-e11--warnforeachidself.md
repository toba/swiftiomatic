---
# v2i-e11
title: WarnForEachIdSelf
status: completed
type: feature
priority: normal
created_at: 2026-04-30T21:36:52Z
updated_at: 2026-04-30T21:41:28Z
parent: 7h4-72k
sync:
    github:
        issue_number: "587"
        synced_at: "2026-04-30T23:13:24Z"
---

Warn on `ForEach(_, id: \.self)` — fragile when the value type isn't both Hashable and stable. The recommended fix is to give the model an explicit `Identifiable` conformance.

## Decisions

- Group: `.idioms`
- Default: `.warn`
- Lint-only.
- Trigger: `ForEach(<expr>, id: \.self) { ... }` — match the `id` argument as a key path expression with a single `.self` component.

## Plan

- [x] Failing test
- [x] Implement `WarnForEachIdSelf`
- [x] Verify test passes; regenerate schema



## Summary of Changes

- LintSyntaxRule on `FunctionCallExprSyntax`. Matches `ForEach(_, id: \.self)` by checking the `id` argument is a key path expr with single `.self` property component.
- 4/4 tests passing.
- Schema regenerated.
