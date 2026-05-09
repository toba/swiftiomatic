---
# jpu-805
title: Audit and extend UseContinuousClockNotDate
status: completed
type: task
priority: normal
created_at: 2026-05-09T16:48:37Z
updated_at: 2026-05-09T16:51:09Z
parent: z75-gax
sync:
    github:
        issue_number: "681"
        synced_at: "2026-05-09T17:07:18Z"
---

Item 7 from z75-gax. Existing rule covers Date().timeIntervalSince(start) and Date().timeIntervalSinceNow. Extend to Date.now.timeIntervalSince(...) and Date.now.timeIntervalSinceNow.

- [x] Write tests for new patterns
- [x] Extend rule
- [x] Verify build/test passes



## Summary of Changes

- Audit: existing `UseContinuousClockNotDate` already covered `Date().timeIntervalSince(start)` and `Date().timeIntervalSinceNow` (initializer form).
- Extended `Sources/SwiftiomaticKit/Rules/Idioms/UseContinuousClockNotDate.swift` to also match `Date.now` (member-access form): replaced `isDateInitializerCall` with `isDateNowExpression` matching either `Date()` or `Date.now`.
- Added 2 tests in `Tests/SwiftiomaticTests/Rules/UseContinuousClockNotDateTests.swift` covering `Date.now.timeIntervalSince(start)` and `Date.now.timeIntervalSinceNow`.
- Full test suite: 3338 passed, 0 failed.
