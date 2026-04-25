---
# axa-3eo
title: singleLineBodies inline doesn't collapse for-in body that fits on one line
status: ready
type: bug
priority: normal
created_at: 2026-04-25T20:04:05Z
updated_at: 2026-04-25T20:04:05Z
sync:
    github:
        issue_number: "414"
        synced_at: "2026-04-25T20:19:37Z"
---

## Problem

When `singleLineBodies` is set to `inline`, a `for-in` loop with a single-statement body that would fit on one line is not being collapsed.

## Example

This input:

```swift
for ruleName in ruleNames {
    ruleMap[ruleName, default: []].append(sourceRange)
}
```

should be formatted as:

```swift
for ruleName in ruleNames { ruleMap[ruleName, default: []].append(sourceRange) }
```

when it fits within the configured line width.

## Tasks

- [ ] Add failing test reproducing the issue (for-in with single statement, fits on one line, `singleLineBodies: inline`)
- [ ] Locate the singleLineBodies inline handling and identify why for-in is skipped
- [ ] Implement fix
- [ ] Confirm test passes
- [ ] Verify no regressions in other singleLineBodies tests
