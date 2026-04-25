---
# qq0-i6t
title: 'CollapseSimpleIfElse: single-line if/else for simple cases'
status: completed
type: feature
priority: normal
created_at: 2026-04-25T02:36:12Z
updated_at: 2026-04-25T03:08:41Z
sync:
    github:
        issue_number: "397"
        synced_at: "2026-04-25T03:51:30Z"
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

- [x] Create `Sources/SwiftiomaticKit/Syntax/Rules/Wrap/CollapseSimpleIfElse.swift`
- [x] Visit `IfExprSyntax`, walk `else if` chain, validate each branch has one statement
- [x] Skip empty branches, branches with comments, branches with multiple statements
- [x] Compute collapsed length, check against `LineLength`
- [x] Register via `swift run generate-swiftiomatic`
- [x] Add tests in `Tests/SwiftiomaticTests/Rules/Wrap/CollapseSimpleIfElseTests.swift`
- [x] Verify with xc-swift diagnostics



## Summary of Changes

- Added `CollapseSimpleIfElse` format rule in `Wrap/` group; default off (`lint: no, rewrite: false`).
- Walks the entire if/else-if/else chain from the top; validates each branch has exactly one statement with no comments; checks collapsed length against `LineLength`.
- Complements `PreferTernary` for cases ternary can't reach: `if let`/`if case`, `if #available`, multi-clause conditions.
- Deliberately skips bare `if` (no else) — those fall under `WrapSingleLineBodies` inline mode.
- 13 tests covering `if let`/`if case`/return pairs/else-if chains/length cutoff/comment rejection/nested inside functions.
- All 170 Wrap tests pass. Schema.json regenerated to include the rule.
- Note: `swiftiomatic.json` (user config) is jig-protected; user may add the rule via `sm update` if they want it enabled or listed.
