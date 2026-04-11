---
# 0ht-8p0
title: Migrate remaining 44 test files to swift-format assert pattern
status: completed
type: task
priority: normal
created_at: 2026-04-11T15:39:02Z
updated_at: 2026-04-11T16:50:08Z
parent: np8-60m
sync:
    github:
        issue_number: "175"
        synced_at: "2026-04-11T17:10:02Z"
---

Migrate 44 rule test files from old `verifyRule` pattern to new Apple swift-format `assertLint`/`assertFormatting`/`assertViolates`/`assertNoViolation` pattern.

## Plan
- [x] Study old and new patterns
- [x] Migrate AccessControl tests (2 files)
- [x] Migrate ControlFlow tests (2 files)
- [x] Migrate Documentation tests (3 files)
- [x] Migrate Infrastructure tests (2 files)
- [x] Migrate LineFormatting tests (7 files)
- [x] Migrate Metrics tests (5 files)
- [x] Migrate Naming tests (7 files)
- [x] Migrate Ordering tests (4 files)
- [x] Migrate Redundancy tests (5 files)
- [x] Migrate Spacing tests (2 files)
- [x] Migrate TypeSafety tests (5 files)
- [x] Migrate Wrapping tests (1 file)
- [x] Build and verify all tests pass


## Summary of Changes

Migrated all 44 non-generated test files from old `verifyRule` pattern to Apple swift-format style `assertLint`/`assertFormatting`/`assertViolates`/`assertNoViolation` pattern.

- Build: passes (0 errors)
- Tests: 463 passed, 15 failed (all 15 failures are pre-existing in unchanged files)
- Fixed 3 build errors: wrong module import in 4 Ordering files, 2 Sendable conformance issues
- 1 test fix: LintModifierOrderTests violation marker position
