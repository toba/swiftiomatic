---
# we9-2fx
title: 'Line break precedence: prefer splitting at ?? / + over = assignment'
status: review
type: bug
priority: normal
created_at: 2026-04-24T18:44:01Z
updated_at: 2026-04-24T20:12:28Z
sync:
    github:
        issue_number: "374"
        synced_at: "2026-04-24T20:43:39Z"
---

## Problem

When a line with assignment + expression exceeds the line limit, the formatter currently breaks after `=`:

```swift
self.words =
            try container.decodeIfPresent([String].self, forKey: .words)
            ?? AcronymsConfiguration().words
```

## Expected

Keep the assignment on one line and break at the lower-precedence operator instead:

```swift
self.words = try container.decodeIfPresent([String].self, forKey: .words)
    ?? AcronymsConfiguration().words
```

## Line Break Precedence

When a line must wrap, prefer splitting at (highest to lowest priority):

1. Binary operators (`??`, `+`, `&&`, `||`, etc.)
2. `.` in method/property chains
3. `=` assignment (last resort)

## Tasks

- [x] Investigate how break priorities are assigned in token stream layout
- [x] Adjust break priority so `=` breaks are lower priority than binary operator breaks
- [x] Add test case for this scenario
- [x] Verify existing tests still pass


## Summary of Changes

Modified the Oppen pretty-printer token stream to prefer breaking at binary operators (`??`, `+`, `&&`, `||`, `as`, etc.) over breaking at `=` in assignment expressions.

### Mechanism

In the Oppen algorithm, a break's "length" determines whether it fires. By placing the `open` group token *before* the `=` break (instead of after), the break's length is bounded by the next operator break within the group, rather than extending to the end of the stream. This makes the `=` break less eager — it only fires when the first operand of the RHS doesn't fit on the line.

### Files Changed

- `TokenStream+Operators.swift` — `visitInfixOperatorExpr` for assignment operators
- `TokenStream+Bindings.swift` — `visitPatternBinding` for `let`/`var` declarations  
- `TokenStream+Appending.swift` — Added `hasLeadingLineComments` helper
- 13 test files updated with new expectations

### Guard for Comments

When comments exist between `=` and the RHS expression (e.g. `let z = // comment\n  1 + 2`), the optimization is skipped to preserve correct comment indentation and formatter idempotency.
