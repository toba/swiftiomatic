---
# fg4-zkc
title: Fix naming convention violations
status: ready
type: task
priority: low
created_at: 2026-04-14T02:42:23Z
updated_at: 2026-04-14T02:42:23Z
parent: kqx-iku
sync:
    github:
        issue_number: "272"
        synced_at: "2026-04-14T02:58:31Z"
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
- [ ] Check for swift-syntax name collisions before renaming protocols
- [ ] Rename OrderedImports boolean variables
- [ ] Build and test
