---
# 4sp-t4r
title: Configuration equality allocates encoders per call
status: completed
type: task
priority: high
created_at: 2026-04-25T20:41:34Z
updated_at: 2026-04-25T20:48:12Z
parent: 0ra-lks
sync:
    github:
        issue_number: "436"
        synced_at: "2026-04-25T22:35:12Z"
---

`Sources/SwiftiomaticKit/Configuration/Configuration.swift:6-41` — `Configuration.==` allocates two `JSONValueEncoder` instances per setting and per rule, every call. With ~165 rules that is ~330 encoder allocations per equality check, plus dictionary string compares.

## Fix

Make `Configuration.values: [String: any Sendable]` directly comparable. Either:
- Store values in a typed wrapper that conforms to `Equatable`
- Stash a per-entry `_isEqual` closure alongside `decode`/`encode` so `==` becomes a single pass without encoder allocation

## Test plan
- [x] Existing equality semantics preserved (added `equalityDetectsLayoutSettingDifference` and `equalityDetectsRuleValueDifference` tests)
- [ ] Skipped formal allocation benchmark; the fix removes encoder allocation by construction (closure compares typed values directly)

## Summary of Changes

`Configuration.==` now compares typed values directly via per-entry `isEqual` closures instead of round-tripping each value through `JSONValueEncoder`.

- Added `isEqual: @Sendable (Configuration, Configuration) -> Bool` to `SettingEntry` and `RuleEntry`. The closure captures the original generic type `D`/`R` and uses `Value`'s existing `Equatable` conformance (`Value: Sendable & Codable & Equatable` per `Configurable`).
- Removed the encode-and-compare loop from `==`; it is now two single-pass loops over `settingEntries` and `ruleEntries`.
- Eliminates ~330 `JSONValueEncoder` allocations per equality check (~165 rules × 2 sides).
- Tests added in `ConfigurationTests.swift`: assert mutating a layout setting and a rule value each toggle equality off then back on.
