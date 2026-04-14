---
# fg4-zkc
title: Fix naming convention violations
status: completed
type: task
priority: low
created_at: 2026-04-14T02:42:23Z
updated_at: 2026-04-14T03:06:16Z
parent: kqx-iku
sync:
    github:
        issue_number: "272"
        synced_at: "2026-04-14T03:07:05Z"
---

## 1. Protocol naming — drop -Protocol suffix
`Sources/Swiftiomatic/Core/SyntaxTraits.swift` defines three protocols with redundant `-Protocol` suffix:
- `CallingExprSyntaxProtocol` (line 16) → `CallingExprSyntax` or keep if collision with swift-syntax type
- `KeywordModifiedExprSyntaxProtocol` (line 43)
- `CommaSeparatedListSyntaxProtocol` (line 71)

**Note:** Verify these don't collide with actual swift-syntax type names before renaming.

## 2. Boolean naming in OrderedImports
`Sources/Swiftiomatic/Rules/OrderedImports.swift` (lines 54, 217-219):
```swift
var declGroup = false
var implementationOnlyGroup = false
var testableGroup = false
```
These don't read as assertions. Consider: `seenDeclImports`, `seenImplementationOnlyImports`, `seenTestableImports`.

## Tasks
- [x] Check for swift-syntax name collisions before renaming protocols (no collisions found)
- [x] Rename OrderedImports boolean variables
- [x] Build and test


## Summary of Changes

- Renamed 3 protocols in `SyntaxTraits.swift`: dropped `-Protocol` suffix (`CallingExprSyntaxProtocol` → `CallingExprSyntax`, etc.); updated all usages in `TokenStreamCreator.swift`
- Renamed 4 boolean variables in `OrderedImports.checkGrouping()`: `declGroup` → `seenDeclImport`, `implementationOnlyGroup` → `seenImplementationOnlyImport`, `testableGroup` → `seenTestableImport`, `codeGroup` → `seenCodeBlock`
- All 2715 tests pass
