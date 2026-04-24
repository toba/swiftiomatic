---
# jzn-3n8
title: 'PreferTernary: rewrite simple if-else return to ternary'
status: completed
type: feature
priority: normal
created_at: 2026-04-24T22:06:58Z
updated_at: 2026-04-24T22:18:42Z
sync:
    github:
        issue_number: "380"
        synced_at: "2026-04-24T22:30:45Z"
---

Add a `SyntaxFormatRule` that converts simple if-else statements with single return/expression branches into ternary conditional expressions.

## Examples

**Before:**
```swift
if trailingCount == 1 {
    return convertSingle(...)
} else {
    return convertMultiple(...)
}
```

**After:**
```swift
return trailingCount == 1
    ? convertSingle(...)
    : convertMultiple(...)
```

## Scope

Only convert when:
- if-else has exactly two branches (no else-if chains)
- Each branch is a single statement
- Both branches are either `return expr` or bare expressions (in closures/last-expression contexts)

## Tasks

- [x] Create rule file `Sources/SwiftiomaticKit/Syntax/Rules/Conditions/PreferTernary.swift`
- [x] Create test file `Tests/SwiftiomaticTests/Rules/PreferTernaryTests.swift`
- [x] Verify tests pass and build succeeds
