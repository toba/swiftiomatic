---
# qbo-di2
title: 'PreferIfElseChain: convert series of early returns to chained if/else'
status: completed
type: feature
priority: normal
created_at: 2026-04-24T22:33:58Z
updated_at: 2026-04-24T22:43:59Z
sync:
    github:
        issue_number: "386"
        synced_at: "2026-04-24T22:54:06Z"
---

## Description

New lint/format rule that detects a series of early `return` statements followed by a final `return`, and converts them into a single chained `if/else` expression.

## Example

**Before:**
```swift
if case .spaces = $0 { return true }
if case .tabs = $0 { return true }
return false
```

**After:**
```swift
if case .spaces = $0 {
    true
} else if case .tabs = $0 {
    true
} else {
    false
}
```

## Tasks

- [x] Create issue
- [x] Survey codebase for existing patterns and reference rules
- [x] Write failing tests
- [x] Implement the rule
- [x] Verify tests pass


## Summary of Changes

New `PreferIfElseChain` format rule in `Sources/SwiftiomaticKit/Syntax/Rules/Conditions/PreferIfElseChain.swift` with 8 tests in `Tests/SwiftiomaticTests/Rules/PreferIfElseChainTests.swift`.

The rule detects 2+ consecutive `if` statements (each with a single `return` body and no `else` branch) followed by a trailing `return`, and converts them into a single chained `if/else` expression. Requires at least 2 if-branches to trigger (a single if + return is left alone).
