---
# w98-vai
title: Fix O(n²) performance anti-patterns
status: completed
type: bug
priority: high
created_at: 2026-04-14T02:41:43Z
updated_at: 2026-04-14T02:56:50Z
parent: kqx-iku
sync:
    github:
        issue_number: "273"
        synced_at: "2026-04-14T02:58:31Z"
---

Two quadratic-time patterns found in the codebase.

## 1. RuleMask.swift — Array.insert(at: 0) in loop
**File:** `Sources/Swiftiomatic/Core/RuleMask.swift:268`

```swift
lineComments.insert(text, at: 0)  // O(n) insert, called in loop = O(n²)
```

The loop (lines 260-276) reverses trivia then inserts at index 0 to reverse again. Fix: collect normally and reverse once at the end, or use a Deque.

## 2. GroupNumericLiterals.swift — String insert in loop
**File:** `Sources/Swiftiomatic/Rules/GroupNumericLiterals.swift:72-78`

```swift
while i * stride < digits.count {
    newGrouping.insert("_", at: digits.count - i * stride)  // O(n) per insert
}
```

Fix: build the string from right to left, or use `joined(separator:)` with stride-based chunks.

## Tasks
- [x] Fix RuleMask.swift insert(at: 0) pattern
- [x] Fix GroupNumericLiterals.swift insert pattern
- [x] Verify with RuleExampleTests batch


## Summary of Changes

- **RuleMask.swift**: Replaced `insert(at: 0)` in reversed trivia loop with `append` + `reverse()` at end — O(n) instead of O(n²)
- **GroupNumericLiterals.swift**: Replaced repeated `Array.insert(_:at:)` with right-to-left character accumulation + `reverse()` — O(n) instead of O(n²)
- All 2715 tests pass
