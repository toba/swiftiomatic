---
# 886-v5f
title: Prefer breaking at . over = in long assignments
status: review
type: bug
priority: normal
created_at: 2026-04-24T01:24:48Z
updated_at: 2026-04-24T01:55:43Z
sync:
    github:
        issue_number: "363"
        synced_at: "2026-04-24T02:26:01Z"
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

- [x] Study how the `TokenStream` / `PrettyPrinter` currently ranks break candidates in assignment expressions
- [x] Change break priority so `.` breaks are preferred over `=` breaks
- [ ] Add tests: chained methods, closures, single-line fits, fallback to `=` break (existing tests all pass)
- [x] Verify no regressions in existing formatting


## Summary of Changes

The break after `=` in assignments (both `InfixOperatorExprSyntax` and `PatternBindingSyntax`) now uses `ignoresDiscretionary: true`. This means the formatter decides based on content fit rather than preserving user-entered newlines at the `=` position. Breaks at `.` and `+` still respect existing newlines normally.

**Files changed:**
- `TokenStream+Operators.swift` — already committed in prior work
- `TokenStream+Bindings.swift` — `let/var` declarations now also ignore discretionary newlines after `=`
- `RespectsExistingLineBreaksTests.swift` — updated expected output to reflect `var x: Int = 100` staying on one line
