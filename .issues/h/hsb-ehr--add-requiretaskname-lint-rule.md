---
# hsb-ehr
title: Add RequireTaskName lint rule
status: completed
type: feature
priority: normal
created_at: 2026-06-03T03:14:29Z
updated_at: 2026-06-03T03:19:20Z
sync:
    github:
        issue_number: "718"
        synced_at: "2026-06-03T03:27:49Z"
---

Lint rule that warns on Tasks missing a `name:` parameter. Targets Swift 6.2/iOS 26+ `Task(name:)`, `Task.detached(name:)`, `Task.immediate(name:)`, `Task.immediateDetached(name:)`, and `TaskGroup.addTask(name:)` / `addTaskUnlessCancelled(name:)`. Inspired by https://artemnovichkov.com/blog/task-names-in-swift-concurrency. Default: enabled, warn.

- [x] Add `RequireTaskName` rule under `Sources/SwiftiomaticKit/Rules/Unsafety/`
- [x] Tests under `Tests/SwiftiomaticTests/Rules/RequireTaskNameTests.swift`
- [x] Run generator
- [x] Build & run filtered tests



## Summary of Changes

- Added `RequireTaskName` lint rule (group `unsafety`) flagging unnamed `Task { }`, `Task.detached`, `Task.immediate`, `Task.immediateDetached`, `addTask`, and `addTaskUnlessCancelled` calls.
- Default handling is the project default for lint rules: enabled, warn.
- 12 tests in `RequireTaskNameTests` cover each kind plus a `Task.currentName` member-access negative case.
- Generator run; `Pipelines+Generated.swift` etc. rewritten to register the rule.
