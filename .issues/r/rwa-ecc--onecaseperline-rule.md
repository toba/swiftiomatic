---
# rwa-ecc
title: OneCasePerLine rule
status: completed
type: task
priority: normal
created_at: 2026-04-12T23:57:19Z
updated_at: 2026-04-13T00:15:17Z
parent: shb-etk
sync:
    github:
        issue_number: "245"
        synced_at: "2026-04-13T00:25:21Z"
---

Enum cases with associated values or raw values should each have their own `case` declaration. Plain cases without payloads are fine grouped.

**swift-format reference**: `OneCasePerLine.swift` in `~/Developer/swiftiomatic-ref/`

Triggers:
```swift
enum Foo {
    case a(Int), b(String)    // ← each needs its own case
    case c = 1, d = 2         // ← each needs its own case
}
```

Does NOT trigger:
```swift
enum Foo {
    case a, b, c              // ← fine, no payloads
    case d(Int)               // ← fine, single case
}
```

## Checklist

- [x] Decide scope: lint+correctable
- [x] Read reference implementation in swift-format
- [x] Create rule file with id `one_case_per_line`
- [x] Detect `case` declarations with multiple elements where any element has associated values
- [x] Detect `case` declarations with multiple elements where any element has a raw value
- [x] Skip `case` declarations where all elements are plain (no payload, no raw value)
- [x] Implement correction: split into separate `case` declarations preserving attributes and comments
- [x] Add non-triggering and triggering examples
- [x] Run `swift run GeneratePipeline`
- [x] Verify examples pass via RuleExampleTests


## Summary of Changes

Created `OneCasePerLineRule` (lint, correctable) at `Rules/Redundancy/Syntax/`. Rewriter splits multi-element case declarations when any element has associated values or raw values, grouping plain cases together. Preserves leading trivia/comments on the first split.
