---
# k64-28r
title: 'fix: compact single function-call argument broken to new line when src has newline after paren'
status: completed
type: bug
priority: normal
created_at: 2026-05-22T15:25:55Z
updated_at: 2026-05-22T15:29:40Z
sync:
    github:
        issue_number: "697"
        synced_at: "2026-05-22T15:30:23Z"
---

When a function call has a single labeled argument whose value is a FunctionCallExprSyntax (e.g. `.starts(with: symbol.utf8.reversed())`), and the source has a discretionary newline after `(`, the formatter preserves it and produces:

```swift
.starts(
    with: symbol.utf8.reversed()
)
```

even though the argument fits on one line. The fix is to mark the `.break(.open, size: 0)` after `(` with `ignoresDiscretionary: true` when `isCompactSingleFunctionCallArgument` returns true, so the source newline is discarded when the arg fits.

## Tasks
- [x] Write a failing test
- [x] Apply the fix
- [x] Confirm test passes


## Summary of Changes

In `arrangeFunctionCallArgumentList`, when `isCompactSingleFunctionCallArgument` is true (single arg is array, dict, closure, or function call), the `.break(.open)` after `(` and `.break(.close)` before `)` now use `ignoresDiscretionary: true`. This discards source-level newlines that the user placed around the argument, letting the formatter collapse the call to one line when it fits — matching how the `label:` break already works.
