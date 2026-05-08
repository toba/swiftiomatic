---
# exi-x3c
title: Assignment-RHS chain precedence broken when prefixed with try/await
status: completed
type: bug
priority: normal
created_at: 2026-05-08T04:52:10Z
updated_at: 2026-05-08T05:18:40Z
sync:
    github:
        issue_number: "651"
        synced_at: "2026-05-08T05:22:45Z"
---

Repro:

```swift
let location = try Citation
    .join(CitationGroup.all) { $0.groupID.eq($1.id) }
    .where({ c, _ in c.id.eq(#bind(citationID)) })
    .select({ c, g in (c.referenceID, g.projectID) })
    .fetchOne(db)
```

Gets formatted to:

```swift
let location =
    try Citation
    .join(CitationGroup.all) { $0.groupID.eq($1.id) }
    ...
```

The `=` break fires before the chain's `.` breaks, violating the documented precedence (`.` rank 2 > `=` rank 4 last resort).

Cause: `isMemberAccessChain` in TokenStream+Appending.swift does not unwrap `KeywordModifiedExprSyntax` (try/await), so a `try chain` RHS reports `hasMemberChain == false`, missing the `canGroupBeforeBreak` branch in `arrangeAssignmentBreaks`.

Fix: unwrap `KeywordModifiedExprSyntax` in `isMemberAccessChain` (mirrors `isCompoundExpression`).

- [x] Add failing test in AssignmentExprTests
- [x] Add KeywordModifiedExpr unwrap in isMemberAccessChain
- [x] Add chain-precedence open/close under isKeywordModified in visitFunctionCallExpr
- [ ] Verify full test suite passes (blocked by concurrent agent's broken RewritePipeline.swift)



## Status

Fix implemented in two places:
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Appending.swift` — `isMemberAccessChain` now unwraps `KeywordModifiedExprSyntax` (try/await/unsafe).
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Collections.swift` — in `visitFunctionCallExpr`, the chain-precedence `.open`/`.close` around `.method(args)` is now applied even when the call is wrapped in a keyword modifier (try/await/unsafe). The keyword-modifier group only spans the head (`try base`) so chain-break precedence still needs its own group around `.method(args)`. Only the redundant base-name group is suppressed under `isKeywordModified`.

Verified via test `AssignmentExprTests/assignmentWithTryPrefixedChainRHS` running successfully prior to a concurrent agent leaving `Sources/SwiftiomaticKit/Syntax/Rewriter/RewritePipeline.swift` in a broken state (botched sed leaving `run\1` markers). That broken file blocks the SwiftiomaticBuildToolPlugin pre-build lint and prevents further test runs in this session — outside the scope of this issue.



## Summary of Changes

- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Appending.swift`: `isMemberAccessChain` unwraps `KeywordModifiedExprSyntax` so `try`/`await`/`unsafe` chains take the `canGroupBeforeBreak` branch in `arrangeAssignmentBreaks`.
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Collections.swift`: in `visitFunctionCallExpr`, the chain-precedence `.open`/`.close` around `.method(args)` now fires even when the call is wrapped in a keyword modifier; only the redundant base-name group is suppressed under `isKeywordModified`.
- `Tests/SwiftiomaticTests/Layout/AssignmentExprTests.swift`: new `assignmentWithTryPrefixedChainRHS` regression test.
