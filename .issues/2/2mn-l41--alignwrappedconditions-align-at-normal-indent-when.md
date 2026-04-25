---
# 2mn-l41
title: 'AlignWrappedConditions: align at normal indent when beforeGuardConditions break is set'
status: completed
type: bug
priority: normal
created_at: 2026-04-25T03:08:29Z
updated_at: 2026-04-25T03:16:13Z
sync:
    github:
        issue_number: "399"
        synced_at: "2026-04-25T03:51:30Z"
---

When the `beforeGuardConditions` line break setting is TRUE, the conditions appear on a new line after `guard`. In that case, wrapped conditions should be aligned at the normal indentation position (not aligned under the first condition, which would be over-indented).

## Tasks
- [x] Add a failing test that exercises the case where `beforeGuardConditions` is set
- [x] Update `AlignWrappedConditions` to use normal indent alignment when the guard's first condition starts on a new line
- [x] Verify existing tests still pass



## Summary of Changes

- `Sources/SwiftiomaticKit/Layout/Rules/BeforeGuardConditions.swift`: gate the `+6` alignment break behind `!config[BeforeGuardConditions.self]` so guard conditions only align under the first condition when the first condition stays on the `guard` line. When `beforeGuardConditions` is true, fall back to `.continuation` indent.
- `Tests/SwiftiomaticTests/Layout/AlignWrappedConditionsTests.swift`: existing `guardAlignsTwoConditions` and `guardNestedIndentation` now use a config that explicitly sets `beforeGuardConditions = false` (since `Configuration.forTesting` falls through to the default `true`). Added `guardBeforeGuardConditionsUsesNormalIndent` and `guardBeforeGuardConditionsNestedUsesNormalIndent` covering the new behavior.
- Full test suite: 2557/2557 passing.
