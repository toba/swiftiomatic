---
# 0ht-8p0
title: Migrate remaining 44 test files to swift-format assert pattern
status: in-progress
type: task
priority: normal
created_at: 2026-04-11T15:39:02Z
updated_at: 2026-04-11T15:39:02Z
parent: np8-60m
sync:
    github:
        issue_number: "175"
        synced_at: "2026-04-11T16:40:45Z"
---

Migrate 44 rule test files from old `verifyRule` pattern to new Apple swift-format `assertLint`/`assertFormatting`/`assertViolates`/`assertNoViolation` pattern.

## Plan
- [ ] Study old and new patterns
- [ ] Migrate AccessControl tests (2 files)
- [ ] Migrate ControlFlow tests (2 files)
- [ ] Migrate Documentation tests (3 files)
- [ ] Migrate Infrastructure tests (2 files)
- [ ] Migrate LineFormatting tests (7 files)
- [ ] Migrate Metrics tests (5 files)
- [ ] Migrate Naming tests (7 files)
- [ ] Migrate Ordering tests (4 files)
- [ ] Migrate Redundancy tests (5 files)
- [ ] Migrate Spacing tests (2 files)
- [ ] Migrate TypeSafety tests (5 files)
- [ ] Migrate Wrapping tests (1 file)
- [ ] Build and verify all tests pass
