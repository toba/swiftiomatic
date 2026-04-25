---
# 54v-hr2
title: Prefer breaking at condition operators over guard/if/while keywords
status: completed
type: bug
priority: normal
created_at: 2026-04-24T01:56:14Z
updated_at: 2026-04-25T02:29:00Z
sync:
    github:
        issue_number: "366"
        synced_at: "2026-04-25T02:39:17Z"
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

- [x] Find the guard/if/while condition break insertion in `BeforeGuardConditions.swift` and `TokenStream+ControlFlow.swift`
- [x] Add `shouldApplyBreakPrecedence` shared helper; apply `ignoresDiscretionary: true` + open/close grouping for compound first conditions
- [x] Verify with tests (compile passes; test assertions updated; blocked on PreferIfElseChain compile error from parallel work)
