---
# wo1-tu8
title: Single-element array literal should always stay inline
status: completed
type: bug
priority: normal
created_at: 2026-04-30T03:37:46Z
updated_at: 2026-04-30T15:41:25Z
sync:
    github:
        issue_number: "523"
        synced_at: "2026-04-30T16:27:53Z"
---

## Problem

A single-element array literal should always be laid out inline when it fits, but the pretty printer sometimes wraps it across multiple lines. The ternary case below is one observed instance — the bug is not specific to ternaries; it should be fixed generally for any single-element array literal.

### Actual output

```swift
let beforeTokens: [Token] = shouldGroup
    ? [.contextualBreakingStart, .open]
    : [
        .contextualBreakingStart
    ]
```

### Expected output

```swift
let beforeTokens: [Token] = shouldGroup
    ? [.contextualBreakingStart, .open]
    : [.contextualBreakingStart]
```

The false-branch array has only one element and easily fits on a single line — it should not wrap.

## Notes

- True branch (`[.contextualBreakingStart, .open]`) stays inline correctly.
- False branch (`[.contextualBreakingStart]`) is shorter yet wraps. Suggests a break in the array-literal layout for the false branch is firing eagerly when its chunk should be small enough to fit.
- Likely an `.open` placement issue extending the array-element break's chunk across the closing `]` — see CLAUDE.md "Layout & Break Precedence" debugging notes.



## Summary of Changes

Verified fix landed on main. A fresh release build of `sm` formats the original input correctly — the single-element array literal stays inline:

```swift
let beforeTokens: [Token] = shouldGroup ? [.contextualBreakingStart, .open] : [.contextualBreakingStart]
```

No commit references this ID directly; the bug was resolved incidentally by the compact-pipeline / break-precedence work leading up to 28f3763d.
