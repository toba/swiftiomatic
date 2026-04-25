---
# h9e-gvj
title: 'PreferIfElseChain: don''t convert chained returns when not at implicit-return position'
status: completed
type: bug
priority: high
created_at: 2026-04-25T03:14:08Z
updated_at: 2026-04-25T03:30:58Z
sync:
    github:
        issue_number: "400"
        synced_at: "2026-04-25T03:51:30Z"
---

## Problem

`PreferIfElseChain` (`Sources/SwiftiomaticKit/Syntax/Rules/Conditions/PreferIfElseChain.swift`) transforms a sequence of chained `if ... { return false }` statements followed by a final `return true` into a single `if/else if/else` expression with bare-value branches — even when the surrounding context is the body of an outer `if`/`switch` case (or any nested control-flow body) that requires explicit `return` statements to actually exit the enclosing function.

The rule's `tryBuildChain` (lines 73-158) only validates the local shape: `>= 2` consecutive `if { return X }` + a trailing `return Y`. It never checks where the resulting expression would sit. If the chain is not the final statement of an implicit-return context (single-expression function/closure, computed property getter, etc.), the rewrite drops semantically meaningful `return`s.

The rewritten form drops the `return` keywords (uses bare expression values like `false` / `true`), which is only valid syntax when the enclosing function/closure body is itself a single if-expression. When the chain lives inside another control-flow body, the transformation produces invalid Swift.

## Example

File: `Sources/SwiftiomaticKit/Syntax/Rules/Wrap/CollapseSimpleIfElse.swift` around line 75 (coincidentally the rule's own source).

### Before (valid)

```swift
case let .codeBlock(block):
    if block.leftBrace.leadingTrivia.containsNewlines { return false }
    if block.leftBrace.trailingTrivia.containsNewlines { return false }
    if block.rightBrace.leadingTrivia.containsNewlines { return false }
    return true
```

### After (invalid — produced by the rule)

```swift
case let .codeBlock(block):
    if block.leftBrace.leadingTrivia.containsNewlines {
        false
    } else if block.leftBrace.trailingTrivia.containsNewlines {
        false
    } else if block.rightBrace.leadingTrivia.containsNewlines {
        false
    } else {
        true
    }
```

This doesn't compile here — the `switch` case is inside a `while true { switch ... }` loop within a function returning `Bool`. The branches need explicit `return` to actually return from the function; bare `false`/`true` are unused expressions.

## Expected

The rule should only fold a chain of `if ... { return X }` + trailing `return Y` into a bare-expression `if/else` chain when the chain is the implicit return value of its enclosing body (i.e., the chain's expression value is itself returned). When the chain consists of separate `return` statements that are not the final expression of the enclosing closure/function, leave them alone — or rewrite preserving `return` in each branch.

## Tasks

- [x] Add failing tests: chain inside switch case, chain inside if body, chain inside loop body, chain not at start of body.
- [x] Add `parentAllowsImplicitReturn` check + require `startingAt == 0 && endIndex == items.count`.
- [x] Verify the fix with the rule's own source code (it should not break itself).



## Summary of Changes

**`Sources/SwiftiomaticKit/Syntax/Rules/Conditions/PreferIfElseChain.swift`**
- Replaced the multi-position chain loop in `visit(_:)` with a single attempt at index 0 that requires `chain.endIndex == items.count` (chain must consume the entire item list).
- Added `parentAllowsImplicitReturn(_:)` guard. The rule now only fires when the items list is hosted by `ClosureExprSyntax`, `AccessorBlockSyntax`, `SourceFileSyntax`, or a `CodeBlockSyntax` whose parent is `FunctionDeclSyntax` or `AccessorDeclSyntax` — i.e., contexts where a trailing bare expression becomes the implicit return value.
- Switch cases, if/else bodies, loops (`for`/`while`/`repeat`), `do`/`catch`/`defer`/`guard` bodies, and initializer/deinitializer bodies are all rejected.

**`Tests/SwiftiomaticTests/Rules/PreferIfElseChainTests.swift`**
- Added five regression tests covering the rejected contexts: `chainInsideSwitchCaseDoesNotMatch`, `chainInsideIfBodyDoesNotMatch`, `chainInsideLoopBodyDoesNotMatch`, `chainNotAtStartOfFunctionBodyDoesNotMatch`, `chainWithFollowingStatementDoesNotMatch`.
- All 13 tests in the suite pass (8 original + 5 new). Running `sm format` against the originally-affected `CollapseSimpleIfElse.swift` no longer mangles the chained-returns inside the switch case body.
