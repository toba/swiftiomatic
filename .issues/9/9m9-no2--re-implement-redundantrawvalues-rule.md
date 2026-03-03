---
# 9m9-no2
title: Re-implement redundantRawValues rule
status: completed
type: bug
priority: high
created_at: 2026-03-03T00:22:30Z
updated_at: 2026-03-03T00:43:10Z
parent: cix-9mb
sync:
    github:
        issue_number: "146"
        synced_at: "2026-03-03T00:54:46Z"
---

The `redundantRawValues` FormatRule was lost in commit 749ddf4. Needs rewrite as SwiftSyntax rule.

**What it did:** Remove redundant raw string values for String enums where the case name matches the raw value (`case bar = "bar"` -> `case bar`).

Original at `Sources/Swiftiomatic/Rules/Redundancy/Types/RedundantRawValues.swift` (749ddf4^).

- [ ] Rewrite as SwiftSyntaxCorrectableRule
- [ ] Add tests
- [ ] Register in RuleRegistry

\n## Summary of Changes\nRewrote redundantRawValues as SwiftSyntaxCorrectableRule. Removes individual redundant String enum raw values (per-case), more aggressive than RedundantStringEnumValueRule which only fires when all values are redundant.
