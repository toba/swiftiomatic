---
# 9hc-upr
title: Implement RequireSubprocessTeardownSequence rule
status: completed
type: feature
priority: normal
created_at: 2026-05-09T16:48:32Z
updated_at: 2026-05-09T16:51:09Z
parent: z75-gax
sync:
    github:
        issue_number: "680"
        synced_at: "2026-05-09T17:07:17Z"
---

Item 6 from z75-gax. Flag Subprocess.run(...) calls lacking platformOptions: (or passing default PlatformOptions()). Skill §5 'Subprocess orphan processes'.

- [x] Write tests
- [x] Implement rule
- [x] Verify build/test passes



## Summary of Changes

- Added `Sources/SwiftiomaticKit/Rules/Unsafety/RequireSubprocessTeardownSequence.swift` — visits `Subprocess.run(...)` calls; flags when `platformOptions:` is absent (orphan-process risk on cancellation) or when the value is a default-constructed `PlatformOptions()`. Group: `unsafety`.
- Added `Tests/SwiftiomaticTests/Rules/RequireSubprocessTeardownSequenceTests.swift` — 5 tests (missing arg, default `PlatformOptions()`, explicit teardownSequence, opaque value, unrelated `.run`).
- Full test suite: 3338 passed, 0 failed.
