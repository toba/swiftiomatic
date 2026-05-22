---
# b1p-b1d
title: 'fix CI regression: compact single function-call arg with closures collapsed parens'
status: completed
type: bug
priority: normal
created_at: 2026-05-22T15:41:26Z
updated_at: 2026-05-22T15:41:26Z
sync:
    github:
        issue_number: "699"
        synced_at: "2026-05-22T15:41:51Z"
---

The #697 ignoresDiscretionary change applied to any single function-call argument, including those containing trailing closures. For `.iOSSpecificModifier(SpecificType().onChanged { }.onEnded { })` the closure bodies force multi-line layout, and dropping discretionary newlines wrongly hugged the parens, breaking `IfConfigTests.postfixPoundIfWithTypeInModifier`.

## Summary of Changes

Narrowed the `ignoreDiscretionary` condition in `arrangeFunctionCallArgumentList` (TokenStream+Collections.swift) to exclude arguments whose subtree contains a `ClosureExprSyntax`, via a new recursive `containsClosureExpr` helper. The #697 case still collapses; closure-bearing arguments keep proper multi-line layout. Full suite passes.
