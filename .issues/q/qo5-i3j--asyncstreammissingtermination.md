---
# qo5-i3j
title: AsyncStreamMissingTermination
status: completed
type: feature
priority: normal
created_at: 2026-04-30T21:46:25Z
updated_at: 2026-04-30T21:58:02Z
parent: 7h4-72k
sync:
    github:
        issue_number: "573"
        synced_at: "2026-04-30T23:13:20Z"
---

Lint `AsyncStream { continuation in ... }` initializer bodies that call `continuation.yield(...)` but neither call `continuation.finish(...)` nor set `continuation.onTermination = ...`. Without one of those, the stream may leak.

## Decisions

- Group: `.unsafety`
- Default: `.warn`
- Lint-only.
- Trigger: `AsyncStream`/`AsyncThrowingStream` initializer with a closure argument; closure body has `yield` but no `finish` or `onTermination =`.

## Plan

- [x] Failing test
- [x] Implement `AsyncStreamMissingTermination`
- [x] Verify test passes; regenerate schema



## Summary of Changes

- LintSyntaxRule on `AsyncStream` / `AsyncThrowingStream` initializers. Walks the closure with a `ContinuationUsageScanner` that tracks `.yield` calls, `.finish` calls, and `onTermination =` assignments.
- 6/6 tests passing.
- Schema regenerated.
