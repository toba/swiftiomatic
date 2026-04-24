---
# 886-v5f
title: Prefer breaking at . over = in long assignments
status: in-progress
type: bug
priority: normal
created_at: 2026-04-24T01:24:48Z
updated_at: 2026-04-24T01:27:32Z
sync:
    github:
        issue_number: "363"
        synced_at: "2026-04-24T01:41:18Z"
---

## Problem

When a long assignment exceeds `lineLength`, the pretty-printer has multiple candidate break points but currently always breaks after `=` first, pushing the entire RHS down:

```swift
components =
    path
    .split(separator: "/", omittingEmptySubsequences: false)
    .map { ... }
```

## Expected

When a chained expression overflows, break at `.` (method chains) first, keeping the first RHS token on the `=` line:

```swift
components = path
    .split(separator: "/", omittingEmptySubsequences: false)
    .map {
        $0.replacingOccurrences(of: "~1", with: "/")
            .replacingOccurrences(of: "~0", with: "~")
    }
```

Only fall back to breaking after `=` when `.`-breaks alone can't satisfy the line length.

## Approach

- [ ] Study how the `TokenStream` / `PrettyPrinter` currently ranks break candidates in assignment expressions
- [ ] Change break priority so `.` breaks are preferred over `=` breaks
- [ ] Add tests: chained methods, closures, single-line fits, fallback to `=` break
- [ ] Verify no regressions in existing formatting
