---
# 8d9-7n8
title: NoTaskLocalInDetachedTask
status: scrapped
type: feature
priority: normal
created_at: 2026-04-30T22:49:25Z
updated_at: 2026-04-30T22:49:58Z
parent: 7h4-72k
sync:
    github:
        issue_number: "568"
        synced_at: "2026-04-30T23:13:20Z"
---

Lint references to `@TaskLocal` declarations inside a `Task.detached { ... }` body. Detached tasks don't inherit task-local values, so the read silently sees the default — usually a bug.

## Decisions

- Group: `.unsafety`
- Default: `.warn`
- Lint-only.
- Heuristic: collect names of `@TaskLocal` declarations in the file. Inside any `Task.detached { ... }` closure, flag identifier references matching those names.

## Plan

- [ ] Failing test
- [ ] Implement `NoTaskLocalInDetachedTask`
- [ ] Verify test passes; regenerate schema



## Reasons for Scrapping

The rule needs a file-wide pre-pass to collect `@TaskLocal` names, then another pass to find references inside detached closures. Three nested visitors with mutable state — too much machinery for one finding. Without semantic info we can't do better. Defer until we have proper type/symbol resolution.
