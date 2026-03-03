---
# zxn-d2l
title: Re-implement genericExtensions rule
status: completed
type: bug
priority: high
created_at: 2026-03-03T00:22:30Z
updated_at: 2026-03-03T00:52:20Z
parent: cix-9mb
sync:
    github:
        issue_number: "156"
        synced_at: "2026-03-03T00:54:48Z"
---

The `genericExtensions` FormatRule was lost in commit 749ddf4. Needs rewrite as SwiftSyntax rule.

**What it did:** Prefer generic extensions over type constraints (e.g. `extension Array where Element: Codable` -> `extension Array<Element: Codable>`).

Original at `Sources/Swiftiomatic/Rules/TypeSafety/Types/GenericExtensions.swift` (749ddf4^).

- [ ] Rewrite as SwiftSyntaxCorrectableRule
- [ ] Add tests
- [ ] Register in RuleRegistry
