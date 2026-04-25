---
# qq0-i6t
title: 'CollapseSimpleIfElse: single-line if/else for simple cases'
status: in-progress
type: feature
priority: normal
created_at: 2026-04-25T02:36:12Z
updated_at: 2026-04-25T02:36:12Z
sync:
    github:
        issue_number: "397"
        synced_at: "2026-04-25T02:39:17Z"
---

Collapse a multi-line `if`/`else` (or `else if` chain) onto a single line when:
- Every branch contains exactly one statement
- The collapsed form fits within `LineLength`

Complements `PreferTernary` for cases ternary can't reach: `if let`, `if case`, `if #available`, multi-clause conditions.

## Example

Before:
```swift
if let defaultValue = last?.defaultValue {
    defaultValue
} else {
    last?.type
}
```

After:
```swift
if let defaultValue = last?.defaultValue { defaultValue } else { last?.type }
```

## Tasks

- [ ] Create `Sources/SwiftiomaticKit/Syntax/Rules/Wrap/CollapseSimpleIfElse.swift`
- [ ] Visit `IfExprSyntax`, walk `else if` chain, validate each branch has one statement
- [ ] Skip empty branches, branches with comments, branches with multiple statements
- [ ] Compute collapsed length, check against `LineLength`
- [ ] Register via `swift run generate-swiftiomatic`
- [ ] Add tests in `Tests/SwiftiomaticTests/Rules/Wrap/CollapseSimpleIfElseTests.swift`
- [ ] Verify with xc-swift diagnostics
