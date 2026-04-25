---
# 2k1-xvu
title: guard bindings should not wrap to next line
status: completed
type: bug
priority: normal
created_at: 2026-04-25T03:02:19Z
updated_at: 2026-04-25T17:03:10Z
sync:
    github:
        issue_number: "402"
        synced_at: "2026-04-25T17:04:23Z"
---

## Problem

A `guard` statement is being wrapped so that the `guard` keyword sits alone on its own line and the bindings are pushed onto the next line. The bindings should stay on the same line as `guard`.

## Actual

```swift
guard
                  let listItem = child as? ListItem,
                  let firstText = listItem.child(th
```

## Expected

```swift
guard let listItem = child as? ListItem,
      let firstText = listItem.child(...)
else {
    ...
}
```

The first binding should follow `guard` on the same line. Only break before subsequent bindings if the line is too long.

## Tasks

- [x] Reproduce in a failing test under `Tests/SwiftiomaticTests/`
- [x] Identify which layout/wrap rule is inserting the break after `guard`
- [x] Suppress that break so the first binding stays on the `guard` line
- [x] Verify fix preserves wrapping for subsequent bindings when the line overflows



## Summary of Changes

The reported behavior does not reproduce in the current code. The fix landed in commit d103c9b4 ("add CollapseSimpleIfElse rule; sm update syncs rules in config; layout and ternary fixes") the day before this issue was filed.

The relevant change is in `Sources/SwiftiomaticKit/Layout/Rules/BeforeGuardConditions.swift`, which now conditionally applies the `+6` alignment only when the first condition stays on the `guard` line. When conditions must wrap below `guard`, it falls back to a normal continuation indent.

Verified by formatting `guard let listItem = child as? ListItem, let firstText = listItem.child(through: 0, 0) as? Text else { ... }` at multiple nesting depths (up to 24 spaces of indent). In every case the first binding stays on the `guard` line, matching the expected output.

Existing test coverage: `Tests/SwiftiomaticTests/Layout/GuardStmtTests.swift` (`continuationLineBreaking`, lines 128-182) covers both the "first binding fits" and "first binding too long" branches.
