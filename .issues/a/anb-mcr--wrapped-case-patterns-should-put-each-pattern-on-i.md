---
# anb-mcr
title: Wrapped comma lists should put each element on its own line
status: completed
type: bug
priority: normal
created_at: 2026-04-30T04:02:42Z
updated_at: 2026-04-30T04:23:12Z
sync:
    github:
        issue_number: "529"
        synced_at: "2026-04-30T04:23:38Z"
---

## Problem

When a `switch` case has multiple patterns and they need to wrap, the pretty printer currently keeps multiple patterns on the same line and breaks inconsistently. Each pattern should be on its own line when any wrapping is required.

## Current (incorrect) output

```swift
case let .docLineComment(text), let .docBlockComment(text),
    let .lineComment(text),
    let .blockComment(text):
    text
```

## Expected output

```swift
case let .docLineComment(text),
     let .docBlockComment(text),
     let .lineComment(text),
     let .blockComment(text):
    text
```

## Generalization

The same rule applies to any comma-separated list that needs to wrap — once a wrap is required, every element goes on its own line. No mixing inline and wrapped elements.

Applies to:
- `switch case` patterns (`case let .a(x), let .b(x), …`)
- function parameters (declarations and call sites)
- `if` / `guard` / `while` conditions
- generic parameter and where clauses
- tuple elements
- enum case associated values

### Function parameters example

Current (incorrect):
```swift
func foo(first: Int, second: String,
    third: Double,
    fourth: Bool) { … }
```

Expected:
```swift
func foo(
  first: Int,
  second: String,
  third: Double,
  fourth: Bool
) { … }
```

## Repro

Format a switch case with several long `case let` patterns that exceed the line limit. Observe the mixed inline/wrapped layout.



## Summary of Changes

Promoted the enclosing group around comma-separated lists to `.consistent` so once any element wraps, every element wraps to its own line. Only added/promoted the consistent group when a list has more than one element to avoid perturbing the surrounding break heuristics for single-element cases.

### Code

- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+ControlFlow.swift`
  - `visitIfExpr`: outer `.open(.consistent)` (multi-condition) / `.inconsistent` (single).
  - `visitWhileStmt`: added an outer `.open(.consistent)` group when there are multiple conditions.
  - `visitSwitchCaseLabel`: wrapped `caseItems` in `.open(.consistent)` ... `.close` when there are multiple items.
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+Helpers.swift`
  - `arrangeParenthesizedParameters`: function/closure/enum-case parameter declarations now always use `.open(.consistent)` (replacing `argumentListConsistency()`). Call-site argument grouping is unchanged.
- `Sources/SwiftiomaticKit/Rules/LineBreaks/BeforeGuardConditions.swift`
  - Added an outer `.open(.consistent)` group around guard conditions when there are multiple.

### Tests

- Updated ~50 layout-test golds across SwitchStmtTests, FunctionDeclTests, IfStmtTests, GuardStmtTests, AlignWrappedConditionsTests, ClosureExprTests, EnumDeclTests, InitializerDeclTests, MacroDeclTests, SubscriptDeclTests, ProtocolDeclTests, AssignmentExprTests, CommentTests, StringTests, and SelectionTests to reflect the new all-or-none wrapping behavior.
- Full suite: 3010 / 3010 pass.
