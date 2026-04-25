---
# enu-4zl
title: nestedCallLayout inline mode doesn't collapse chained .with() calls
status: completed
type: bug
priority: normal
created_at: 2026-04-25T19:17:20Z
updated_at: 2026-04-25T19:53:30Z
sync:
    github:
        issue_number: "409"
        synced_at: "2026-04-25T19:53:36Z"
---

## Problem

When `nestedCallLayout` is set to `inline` mode, it should collapse the receiver onto the same line as the opening paren when the argument is a single expression (even a multiline chained call).

## Current behavior

```swift
return .init(
            tryNode
                .with(\.questionOrExclamationMark, nil)
                .with(\.tryKeyword, tryNode.tryKeyword.with(\.trailingTrivia, bangTrailingTrivia))
        )
```

## Expected behavior

```swift
return .init(tryNode
    .with(\.questionOrExclamationMark, nil)
    .with(\.tryKeyword, tryNode.tryKeyword.with(\.trailingTrivia, bangTrailingTrivia))
)
```

The opening paren should hug the call, and the chained `.with(...)` calls should be the only thing on subsequent lines, with the closing paren back at the original indentation.

## Tasks

- [x] Add failing test reproducing the case above
- [x] Fix nestedCallLayout inline mode to collapse single-argument receiver onto opening paren line
- [x] Verify chained `.with(...)` formatting is preserved
- [x] Confirm no regression on other nestedCallLayout cases



## Additional example

```swift
return ExprSyntax(
                        OptionalChainingExprSyntax(
                            expression: typedNode.expression,
                            questionMark: .postfixQuestionMarkToken(
                                leadingTrivia: typedNode.exclamationMark.leadingTrivia,
                                trailingTrivia: typedNode.exclamationMark.trailingTrivia
                            )
                        ))
```

should have been

```swift
return ExprSyntax(OptionalChainingExprSyntax(
    expression: typedNode.expression,
    questionMark: .postfixQuestionMarkToken(
        leadingTrivia: typedNode.exclamationMark.leadingTrivia,
        trailingTrivia: typedNode.exclamationMark.trailingTrivia
    )
))
```



## Third example

```swift
ExprSyntax(
                MacroExpansionExprSyntax(
                    pound: .poundToken(),
                    macroName: .identifier("require"),
                    leftParen: .leftParenToken(),
                    arguments: LabeledExprListSyntax([
                        LabeledExprSyntax(expression: innerExpr)
                    ]),
                    rightParen: .rightParenToken(trailingTrivia: trailingTrivia)
                ))
```

should be

```swift
ExprSyntax(MacroExpansionExprSyntax(
    pound: .poundToken(),
    macroName: .identifier("require"),
    leftParen: .leftParenToken(),
    arguments: LabeledExprListSyntax([
        LabeledExprSyntax(expression: innerExpr)
    ]),
    rightParen: .rightParenToken(trailingTrivia: trailingTrivia)
))
```


## Summary of Changes

`Sources/SwiftiomaticKit/Rules/Wrap/NestedCallLayout.swift`:

- `soleArgumentCall`: switched the multi-line check from `description` to `trimmedDescription` so leading trivia of the inner call no longer triggers a false bail-out. This was the root cause of all 22 inline-mode test failures.
- Added `isCanonicalFullyNested(_:)` and gated chain rebuild strategies on it. Chain strategies rebuild from `trimmedDescription`, which preserves args' internal whitespace; non-canonical inputs (extra indent on the sole arg) now route to the hug fallback instead, where the indent is normalized.
- `tryHugSingleArg`: skip when the arg is already at canonical indent; preserve `rightParen` leading trivia when it has no newline (keeps `))` instead of breaking it onto its own line).

New tests in `Tests/SwiftiomaticTests/Rules/Wrap/NestedCallLayoutTests.swift`:

- `hugsMultilineChainArgument`
- `hugsMultilineNestedCallArgument`
- `hugsMultilineNestedCallWithDeepContent`

Full suite: 2741 passed, 0 failed.
