---
# 59d-d1b
title: 'AlignWrappedConditions: align continuation conditions in if/guard'
status: completed
type: feature
priority: normal
created_at: 2026-04-25T02:04:08Z
updated_at: 2026-04-25T02:39:00Z
sync:
    github:
        issue_number: "395"
        synced_at: "2026-04-25T02:39:17Z"
---

## Description

Wrapped conditions in `if` and `guard` statements should align to the column of the first condition, not use a fixed indentation.

### Before

```swift
if let attr = element.as(AttributeSyntax.self),
    let name = attr.attributeName.as(IdentifierTypeSyntax.self) {
```

```swift
guard let attr = element.as(AttributeSyntax.self),
    let name = attr.attributeName.as(IdentifierTypeSyntax.self) {
```

### After

```swift
if let attr = element.as(AttributeSyntax.self),
   let name = attr.attributeName.as(IdentifierTypeSyntax.self) {
```

```swift
guard let attr = element.as(AttributeSyntax.self),
      let name = attr.attributeName.as(IdentifierTypeSyntax.self) else {
```

## Rules

- `if`: continuation conditions align to column after `if ` (column 3)
- `guard`: continuation conditions align to column after `guard ` (column 6)
- `while`: continuation conditions align to column after `while ` (column 6)
- Applies to all condition list elements after the first

## Tasks

- [x] Create test file with before/after cases
- [x] Implement `AlignWrappedConditions` layout rule
- [x] Register rule in configuration (auto-generated)
- [x] Verify tests pass (9 new + 28 existing)


## Summary of Changes

Added `AlignWrappedConditions` layout rule (bool, default false) that aligns wrapped condition continuations to the column after the keyword:
- `if` -> 3 spaces
- `guard` -> 6 spaces
- `while` -> 6 spaces

Implementation adds `.alignment(spaces:)` case to `OpenBreakKind` in the layout engine, handled in `LayoutCoordinator.currentIndentation`. The alignment break contributes a fixed number of spaces instead of the configured indent unit.

Note: When conditions wrap, `{` still goes to its own line — this is the existing layout engine behavior (reset break fires on continuation lines) and matches standard swift-format output.

### Files changed
- `Sources/SwiftiomaticKit/Layout/Rules/AlignWrappedConditions.swift` (new)
- `Sources/SwiftiomaticKit/Layout/Tokens/Token.swift`
- `Sources/SwiftiomaticKit/Layout/LayoutCoordinator.swift`
- `Sources/SwiftiomaticKit/Layout/Tokens/TokenStream+ControlFlow.swift`
- `Sources/SwiftiomaticKit/Layout/Rules/BeforeGuardConditions.swift`
- `Tests/SwiftiomaticTests/Layout/AlignWrappedConditionsTests.swift` (new)
