---
# 15g-v3q
title: Clean up test infrastructure from Swift review
status: completed
type: task
priority: normal
created_at: 2026-04-11T17:50:48Z
updated_at: 2026-04-11T17:55:05Z
sync:
    github:
        issue_number: "179"
        synced_at: "2026-04-11T18:44:01Z"
---

Fix all 6 findings from /swift review of Tests/SwiftiomaticTests/:

- [x] 1. Delete dead `String+StaticString.swift` (unsafe, unused)
- [x] 2. Replace `checkError` with `#expect(throws:)` (22 call sites)
- [x] 3. Remove dead XCTest `file:/line:` params from `LinterCacheTests`
- [x] 4. Delete dead `lineDiff` function from `RuleTestHelpers`
- [x] 5. Consolidate 3 duplicate rule-registration lazy vars
- [x] 6. Skipped: `macOSSDKPath()` is sync; converting to `Subprocess` (async) would cascade through the test infra


## Summary of Changes

All actionable findings fixed. Item 6 skipped — `macOSSDKPath()` is called synchronously and converting to async `Subprocess` would cascade through the entire test infrastructure for minimal benefit.

Build: passed. Tests: 463 passed, 0 failed.
