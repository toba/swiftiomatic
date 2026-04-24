---
# wq2-tuv
title: 'PreferTrailingClosures: assignment continuation line-breaking is wrong'
status: completed
type: bug
priority: normal
created_at: 2026-04-24T22:08:34Z
updated_at: 2026-04-24T22:27:53Z
sync:
    github:
        issue_number: "381"
        synced_at: "2026-04-24T22:30:44Z"
---

In `Sources/SwiftiomaticKit/Syntax/Rules/Closures/PreferTrailingClosures.swift`, both branches of the `remainingArgs.isEmpty` check (at lines 104–118 and 163–177) break the assignment incorrectly:

```swift
result =
    result
    .with(\.leftParen, nil)
```

Both should keep `result = result` on the same line before breaking to the next:

```swift
result = result
    .with(\.leftParen, nil)
```

This occurs in two places:
- Lines 105–106 and 114–115 (single trailing closure conversion)
- Lines 164–165 and 173–174 (multiple trailing closure conversion)

Also lines 179–180 have the same pattern.

## TODO

- [x] Fix all `result =\n    result` occurrences to `result = result` in PreferTrailingClosures.swift


## Summary of Changes

Fixed 5 occurrences in `PreferTrailingClosures.swift` where `result =` broke to the next line before `result`. All now read `result = result` on a single line with the `.with(…)` chain continuing below.



## Actual Fix (replaces earlier incorrect summary)

The bug was in the formatting *rule*, not the literal code. The formatter was breaking `result = result.with(...)` after `=` instead of at `.`.

**Root cause:** `visitInfixOperatorExpr` and `visitPatternBindingSyntax` did not recognize member access chains as candidates for group-before-break optimization.

**Fix:** Added `isMemberAccessChain(_:)` helper and included it in `canGroupBeforeBreak` in both assignment and pattern binding paths. This makes the Oppen algorithm prefer breaking at `.` over `=`.

**Files changed:**
- `TokenStream+Operators.swift` — assignments (`x = x.foo(...)`)
- `TokenStream+Bindings.swift` — declarations (`let x = y.foo(...)`)
- `TokenStream+Appending.swift` — `isMemberAccessChain(_:)` helper
- `AssignmentExprTests.swift` — 3 new tests (2474 existing tests pass)
