---
# zk2-sks
title: Ternary breaks at '=' before breaking ternary parts
status: completed
type: bug
priority: normal
created_at: 2026-04-25T03:22:57Z
updated_at: 2026-04-25T03:44:05Z
sync:
    github:
        issue_number: "398"
        synced_at: "2026-04-25T03:51:30Z"
---

## Problem

Layout engine breaks at `=` as last resort, but should prefer breaking ternary parts (before `?` and `:`) first.

## Current (wrong) output

```swift
let string =
            expectParameterLabel ? text.string.dropFirst(parameterPrefix.count) : text.string[...]
```

## Expected output

```swift
let string = expectParameterLabel
    ? text.string.dropFirst(parameterPrefix.count)
    : text.string[...]
```

## Rule

Breaking at `=` is always a last resort. The layout engine should prefer breaking ternary parts (before `?` and `:` operators) before falling back to breaking after `=`.

## Tasks

- [x] Add failing test reproducing the bug
- [x] Investigate layout engine break-priority ordering for ternary expressions
- [x] Adjust priority so ternary part breaks are preferred over `=` breaks
- [x] Verify fix with test



## Summary of Changes

**Files changed:**
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Appending.swift` — added `arrangeAssignmentBreaks(afterEqualToken:rhs:operatorExpr:)` helper consolidating the `=`-break placement logic. The helper detects ternary RHS and skips the stacked-indent path, falling through to the group-before-break path so the `=` break length only extends to `expectParameterLabel`. The engine then sees the `=` break fits and prefers breaking before `?`/`:` instead.
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Operators.swift` — replaced the inline 60-line break-placement block in `visitInfixOperatorExpr` (assigning operator branch) with a call to the helper.
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Bindings.swift` — replaced the parallel block in `visitPatternBinding` with a call to the helper.
- `Tests/SwiftiomaticTests/Layout/TernaryExprTests.swift` — added `assignmentPrefersTernaryBreaksOverEqualsBreak`; updated `ternaryExprs`, `ternaryExprsWithMultiplePartChoices`, `ternaryWithWrappingExpressions`, `nestedTernaries` to reflect the new behavior (the `=` no longer breaks first when ternary breaks would suffice).
- `Sources/SwiftiomaticKit/Syntax/DocumentationComment.swift` — re-formatted with the fix; the bug example now produces the correct layout.

**Verification:** Full test suite 2573/2573 passing.

**Behavior:** Breaking after `=` is now last-resort. The Oppen layout engine evaluates each ternary break individually, so when the `:` (false) part has to break, both `?` and `:` end up on their own lines at the same continuation indent. When the false part fits inline with the true part, `:` stays inline.
