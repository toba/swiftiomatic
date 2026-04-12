---
# vjl-m9o
title: 'RedundantBackticks: context-aware backtick removal'
status: completed
type: task
priority: high
created_at: 2026-04-12T19:23:43Z
updated_at: 2026-04-12T19:39:37Z
parent: a9u-qgt
sync:
    github:
        issue_number: "232"
        synced_at: "2026-04-12T20:23:27Z"
---

Add context-dependent logic to `RedundantBackticksRule` matching SwiftFormat's `backticksRequired()` (~80 lines in `ParsingHelpers.swift:1306`). Currently our rule only checks `isSwiftKeyword` + `isValidBareIdentifier`, causing false positives (breaks code) and false negatives (misses safe removals).

Reference: `~/Developer/swiftiomatic-ref/SwiftFormat/Sources/ParsingHelpers.swift:1306-1395`

## Phase 1: Fix False Positives (critical — rule is correctable, so these break code)

- [x] `_`, `$` — always need backticks; our `isValidBareIdentifier` lets `_` through
- [x] `self` — not in `swiftKeywords`; needs backticks except after `.`
- [x] `super`, `nil`, `true`, `false` — not in `swiftKeywords`; need backticks as identifiers
- [x] `Self`, `Any` — need backticks except in type positions (after `:` or `->`)
- [x] `Type` — needs backticks inside type declarations and after `.`
- [x] Accessor keywords (`get`, `set`, `willSet`, `didSet`, `init`, `_modify`) — need backticks only in accessor position

## Phase 2: Fix False Negatives (safe removal opportunities we miss)

- [x] After `.` member access — keywords don't need backticks (except `init`)
- [x] After `::` module selector — keywords allowed except `deinit`, `init`, `subscript`
- [x] Argument position — keywords as parameter labels don't need backticks
- [x] `actor` — safe as rvalue or argument label, needs backticks in binding position

## Phase 3: Examples

- [x] Expanded from 6 to ~30 examples adapted from SwiftFormat reference tests
- [x] Validated automatically by `RuleExampleTests.swift`

## Files

- `Sources/SwiftiomaticKit/Rules/Redundancy/Syntax/RedundantBackticksRule.swift`
- `Sources/SwiftiomaticKit/Support/SwiftKeywords.swift`


## Summary of Changes

Rewrote `RedundantBackticksRule` with context-aware `backtickIsRedundant()` logic adapted from SwiftFormat's `backticksRequired()` (ParsingHelpers.swift:1306). Added handling for:

- Always-required: `_`, `$`, `let`, `var`
- Literal keywords: `self`, `super`, `nil`, `true`, `false`
- Type-position keywords: `Self`, `Any` (safe after `:` or `->`)
- `Type` (needs backticks inside type declarations and after `.`)
- Accessor keywords: `get`, `set`, `willSet`, `didSet`, `init`, `_modify`
- `actor`: safe as rvalue or argument label
- After `.`: keywords safe (except `init`, `Type`)
- After `::` module selector: keywords safe (except `init`, `deinit`, `subscript`)
- Argument position detection via AST parent traversal

Expanded examples from 6 to ~30, adapted from SwiftFormat's 39 test cases.
