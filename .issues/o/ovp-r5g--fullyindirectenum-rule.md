---
# ovp-r5g
title: FullyIndirectEnum rule
status: completed
type: task
priority: normal
created_at: 2026-04-12T23:57:19Z
updated_at: 2026-04-13T00:08:19Z
parent: shb-etk
sync:
    github:
        issue_number: "254"
        synced_at: "2026-04-13T00:25:22Z"
---

When all cases of an enum are marked `indirect`, consolidate to `indirect enum` on the declaration.

**swift-format reference**: `FullyIndirectEnum.swift` in `~/Developer/swiftiomatic-ref/`

Converts:
```swift
enum Tree {
    indirect case leaf(Int)
    indirect case branch(Tree, Tree)
}
```
To:
```swift
indirect enum Tree {
    case leaf(Int)
    case branch(Tree, Tree)
}
```

## Checklist

- [x] Decide scope: lint+correctable
- [x] Read reference implementation in swift-format
- [x] Create rule file with id `fully_indirect_enum`
- [x] Detect enums where every case has `indirect` modifier
- [x] Skip enums that already have `indirect` on the declaration
- [x] Skip enums with zero cases
- [x] Implement correction: move `indirect` to enum declaration, remove from each case
- [x] Add non-triggering and triggering examples
- [x] Run `swift run GeneratePipeline`
- [x] Verify examples pass via RuleExampleTests


## Summary of Changes

Created `FullyIndirectEnumRule` (lint, correctable) at `Rules/Redundancy/Modifiers/`. Detects enums where all cases are marked `indirect` and suggests consolidating to `indirect enum`. Rewriter handles trivia transfer for access modifiers and attributes on cases.
