---
# 0sj-ok2
title: Extract Configuration entry / JSON-modify / range-parse helpers
status: completed
type: task
priority: low
created_at: 2026-04-25T20:43:12Z
updated_at: 2026-04-25T22:16:33Z
parent: 0ra-lks
sync:
    github:
        issue_number: "434"
        synced_at: "2026-04-25T22:35:11Z"
---

Smaller duplication patches in Configuration and CLI argument parsing.

## Findings

- [x] Extracted `Configuration.codingClosures(for:)` returning a `(decode, encode, isEqual)` tuple shared by both `entry(for:)` and `ruleEntry(for:)`
- [x] Extracted `String.qualifiedKeyParts` returning `(group, name)`; replaced 7 inline `split(separator: ".", maxSplits: 1)` sites in Configuration+Update / Configuration+UpdateText. (Did not introduce a `JSONValue.modify(at path:)` helper — the `removeKey`/`insertKey` shapes diverge enough that the simpler key-split helper is the right granularity.)
- [x] Extracted `parseIntPair(_:)` returning `(start, end)?`; both `Range<Int>` and `ClosedRange<Int>` initializers delegate to it

## Test plan
- [x] All 2795 tests pass


## Summary of Changes

- `Configuration.codingClosures(for:)` factors out the shared decode/encode/isEqual closures used by `SettingEntry` and `RuleEntry`.
- `String.qualifiedKeyParts` (`(group: String?, name: String)`) replaces seven inline `split(separator: ".", maxSplits: 1)` sites across `Configuration+Update.swift` and `Configuration+UpdateText.swift`.
- `parseIntPair(_:)` factors out the `start:end` parsing duplicated by `Range<Int>.init(argument:)` and `ClosedRange<Int>.init(argument:)`.
- All 2795 tests pass.
