---
# 21x-kq3
title: Type annotation wraps to own line when RHS is try-wrapped chain
status: completed
type: bug
priority: normal
created_at: 2026-05-23T19:04:29Z
updated_at: 2026-05-23T19:05:03Z
sync:
    github:
        issue_number: "704"
        synced_at: "2026-05-23T19:20:56Z"
---

`let x: [ID?] = try Node.where{}.select{}...` placed the type annotation `[ID?]` on its own line because the `rhsHasInnerBreaks` check in `visitPatternBinding` only inspected the bare initializer value. A `try`/`await` effect wrapper hid the inner member-access chain, so the `:` continuation break was treated as eager.

## Fix
Peel `TryExprSyntax`/`AwaitExprSyntax` wrappers before checking the RHS expression kind in `TokenStream+Bindings.swift`.

- [x] Add regression test (PatternBindingTests.typeAnnotationStaysOnSameLineWithTryMemberChainRHS)
- [x] Peel effect wrappers in rhsHasInnerBreaks

## Summary of Changes
Peeled `TryExprSyntax`/`AwaitExprSyntax` effect wrappers in `visitPatternBinding`'s `rhsHasInnerBreaks` computation (`TokenStream+Bindings.swift`) so the inner member-access chain's break points are recognized. The `:` continuation now stays inline and the type annotation no longer wraps onto its own line. Full suite: 3383 passed.
