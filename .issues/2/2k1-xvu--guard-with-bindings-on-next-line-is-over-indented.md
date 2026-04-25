---
# 2k1-xvu
title: guard bindings should not wrap to next line
status: ready
type: bug
priority: normal
created_at: 2026-04-25T03:02:19Z
updated_at: 2026-04-25T03:02:44Z
sync:
    github:
        issue_number: "402"
        synced_at: "2026-04-25T03:51:30Z"
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

- [ ] Reproduce in a failing test under `Tests/SwiftiomaticTests/`
- [ ] Identify which layout/wrap rule is inserting the break after `guard`
- [ ] Suppress that break so the first binding stays on the `guard` line
- [ ] Verify fix preserves wrapping for subsequent bindings when the line overflows
