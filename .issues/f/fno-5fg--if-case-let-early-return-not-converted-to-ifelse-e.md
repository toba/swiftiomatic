---
# fno-5fg
title: if-case-let early return not converted to if/else expression
status: completed
type: bug
priority: normal
created_at: 2026-04-30T03:41:28Z
updated_at: 2026-04-30T03:49:32Z
sync:
    github:
        issue_number: "524"
        synced_at: "2026-04-30T04:23:38Z"
---

## Problem

The rule that converts early-return patterns into `if/else` expressions (when all branches return) handles plain `if` but not `if case let` pattern matching.

## Example

This pattern is left untouched:

```swift
if case let .array(arr) = storage.value { return arr.count }
return 0
```

It should be rewritten to:

```swift
if case let .array(arr) = storage.value {
    arr.count
} else {
    0
}
```

## Conditions

Same conditions as the existing early-return → if/else conversion rule:
- All branches return
- Function returns a value
- Final `return` follows the `if` directly

## Tasks

- [x] Locate the existing early-return-to-if-else rule
- [x] Add a failing test for the `if case let` pattern
- [x] Extend the rule to handle `if case let` (and likely `if let`, `if case`) condition forms
- [x] Verify test passes
- [x] Confirm no regressions



## Summary of Changes

Root cause: `PreferIfElseChain` (Sources/SwiftiomaticKit/Rules/Conditions/PreferIfElseChain.swift) explicitly required `ifBranches.count >= 2`, rejecting single-`if` + trailing-`return` sequences. The `if case let` form already worked at the syntax level — `ConditionElementListSyntax` is forwarded verbatim — so the only fix needed was relaxing the chain-length gate.

Changes:
- `PreferIfElseChain.swift`: lowered the threshold to `>= 1`; updated the type and `tryBuildChain` doc comments.
- `PreferIfElseChainTests.swift`: replaced `singleIfDoesNotMatch` with two positive tests — `singleIfPlusFinalReturn` and `singleIfCaseLetPlusFinalReturn` (the issue's example verbatim).

Verification: all 14 `PreferIfElseChainTests` pass; existing rejection tests (multi-line bodies, pre-existing else, non-return bodies, switch/loop contexts) continue to pass since none depended on the count threshold.
