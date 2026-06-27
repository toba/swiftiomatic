---
# kxu-zx9
title: 'Port swift-format #1227: ?./! postfix base misread as ternary in wrap logic'
status: completed
type: bug
priority: normal
created_at: 2026-06-27T15:44:39Z
updated_at: 2026-06-27T15:56:59Z
sync:
    github:
        issue_number: "744"
        synced_at: "2026-06-27T16:17:04Z"
---

Port upstream swift-format fix acdf4e4f41d22bb7e04e6efa423432191a844c64 (#1227, fixes #1226).

## Upstream change
In `outermostEnclosingNode` (TokenStreamCreator.swift), when a parenthesized expression is the base of an optional-chaining (`?.`) or force-unwrap (`!`) postfix expression, the wrap logic mistook it for a ternary. Upstream adds a loop that climbs through `OptionalChainingExprSyntax`/`ForceUnwrapExprSyntax` parents (guarded on shared first token) so the outermost node is selected correctly.

```swift
while let parent = parenthesizedExpr?.parent,
  parent.is(OptionalChainingExprSyntax.self) || parent.is(ForceUnwrapExprSyntax.self),
  parent.firstToken(viewMode: .sourceAccurate) == parenthesizedExpr?.firstToken(viewMode: .sourceAccurate)
{
  parenthesizedExpr = parent
}
```

## Tasks
- [x] Locate Swiftiomatic equivalent of outermostEnclosingNode in Sources/SwiftiomaticKit/Layout/
- [x] Add regression test asserting the desired layout (bug did not reproduce)
- [x] Port the fix
- [x] Confirm test passes; run filtered suite then full suite

Upstream test: Tests/SwiftFormatTests/PrettyPrint/MemberAccessExprTests.swift


## Summary of Changes

**The upstream bug (#1226) does not reproduce in Swiftiomatic.** Our pretty printer already glues a parenthesized base's postfix `?`/`!` to the closing paren, so a ternary like `(a ? b : c)?.f` already lays out correctly.

Verified empirically: toggled the fix on/off and diffed formatter output across 9 inputs (ternary/force-unwrap/optional-chaining bases, `&&`/`||` stacked operands, `??`, assignment-RHS, `return`). **All 9 outputs were byte-identical with and without the fix** — the change is a provable no-op for our codebase.

Despite the no-op, I kept a faithful 1:1 port of upstream's 6-line addition to `outermostEnclosingNode` (Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Appending.swift): the function is meant to mirror upstream's `TokenStreamCreator` exactly, so keeping them aligned reduces friction on future ports and safeguards against the bug surfacing if our `insertContextualBreaks` chain handling ever changes.

Added regression guard `MemberAccessExprTests.optionalChainAfterParenthesizedBaseKeepsQuestionMarkAttached` (upstream-exact `if (a ? b : c)?.f {}` at lineLength 10). It passes with or without the fix — it locks in the already-correct behavior.

Note (out of scope): spotted a separate pre-existing oddity — `if (xx && yy)?.foo && zz {}` emits a stray `.foo,` comma. Unrelated to this fix (present both pre- and post-fix). Not chased here.

MemberAccessExprTests: 17 passed.
