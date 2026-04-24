---
# 54v-hr2
title: Prefer breaking at condition operators over guard/if/while keywords
status: ready
type: bug
priority: normal
created_at: 2026-04-24T01:56:14Z
updated_at: 2026-04-24T01:56:14Z
sync:
    github:
        issue_number: "366"
        synced_at: "2026-04-24T02:26:00Z"
---

## Problem

When a `guard` condition exceeds `lineLength`, the formatter breaks after the keyword, pushing the entire condition down:

```swift
guard
    (userRuns.count > 1 && formattedRuns.count > 1)
        || (userRuns.count == 1 && formattedRuns.count == 1 && userIndex == 0)
```

## Expected

Keep the first condition token on the `guard` line, break at operators (`||`, `&&`) instead:

```swift
guard (userRuns.count > 1 && formattedRuns.count > 1)
    || (userRuns.count == 1 && formattedRuns.count == 1 && userIndex == 0)
```

## Approach

Same pattern as 886-v5f (assignment `=` breaks): change the break after `guard`/`if`/`while` keywords to use `ignoresDiscretionary: true` so the formatter decides based on content fit rather than preserving user-entered newlines at the keyword position.

- [ ] Find the guard/if/while condition break insertion in `TokenStream+Conditionals.swift` or similar
- [ ] Change break to use `.elective(ignoresDiscretionary: true)`
- [ ] Verify with tests
