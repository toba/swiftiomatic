---
# 84j-0l7
title: Multi-trailing-closure body wraps inconsistently when call header is wide
status: completed
type: bug
priority: normal
created_at: 2026-05-31T15:28:50Z
updated_at: 2026-05-31T15:41:46Z
sync:
    github:
        issue_number: "714"
        synced_at: "2026-05-31T15:43:19Z"
---

When a function call has multiple trailing closures, the first closure's body stays inline (`{ _ in errors.actions`) while the closing `}` breaks to its own line, producing:

```
.alert(isPresented: $errors.alertPresented, error: errors.current) { _ in errors.actions
} message: { error in Text(error.recoverySuggestion ?? "Try again later.") }
```

Expected: when the call is too long to fit inline, all breaks inside the closure body fire together so `{ _ in`, body, and `}` either all stay inline or all wrap.

Root cause: in `TokenStream+Closures.swift` `visitClosureExpr`, the break after `in` and the break before `}` are independent elective breaks. The break-before-`}` has a chunk extending into the next trailing closure (large, fires) while the break-after-`in` has a tiny chunk (body only, doesn't fire).

Fix: wrap the closure's interior in a consistent group so the inner breaks fire together with the closing-brace break.

- [x] Added failing test `twoTrailingClosuresWideCallHeader`
- [x] Extended force-break rule in `visitFunctionCallExpr` to also fire when there are exactly 2 trailing closures AND the call has parenthesized arguments
- [x] `twoLabeledTrailingClosures` still passes (its case uses no args)
- [x] Full suite green (3413 tests)

## Summary of Changes

`Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Collections.swift` — `visitFunctionCallExpr` now seeds `forcedBreakingClosures` for the 2-closure case when the call has non-empty arguments. The 3+ rule and the empty-args 2-closure (`With { expr } query: { … }`) cases are unchanged.

The chunk-length asymmetry — break-after-`in` sees only the short body while break-before-`}` sees through the next labeled closure — was the underlying cause. Tying both to a single soft break removes the asymmetry without disturbing the well-fitting bj7-vtb case.
