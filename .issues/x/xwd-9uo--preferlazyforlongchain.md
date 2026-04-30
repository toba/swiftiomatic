---
# xwd-9uo
title: PreferLazyForLongChain
status: completed
type: feature
priority: normal
created_at: 2026-04-30T22:50:09Z
updated_at: 2026-04-30T22:54:54Z
parent: 7h4-72k
sync:
    github:
        issue_number: "582"
        synced_at: "2026-04-30T23:13:22Z"
---

Lint chains of 3+ `.map`/`.filter`/`.compactMap`/`.flatMap`/`.prefix`/`.dropFirst` calls. Each step allocates an intermediate; `.lazy` skips the intermediates.

## Decisions

- Group: `.idioms`
- Default: `.warn`
- Lint-only — applying `.lazy` is sometimes wrong (the consumer must accept LazySequence).
- Trigger: a function-call chain ending in one of the named methods, with chain length ≥ 3.

## Plan

- [x] Failing test
- [x] Implement `PreferLazyForLongChain`
- [x] Verify test passes; regenerate schema



## Summary of Changes

- LintSyntaxRule. Walks the receiver chain counting consecutive `.map`/`.filter`/`.compactMap`/`.flatMap`/`.prefix`/`.dropFirst`/`.dropLast` member calls. Emits on the outermost chain link only.
- 5/5 tests passing.
- Schema regenerated.
