---
# l7w-o8p
title: Re-implement simplifyGenericConstraints rule
status: completed
type: bug
priority: high
created_at: 2026-03-03T00:22:30Z
updated_at: 2026-03-03T00:52:20Z
parent: cix-9mb
sync:
    github:
        issue_number: "152"
        synced_at: "2026-03-03T00:54:46Z"
---

The `simplifyGenericConstraints` FormatRule was lost in commit 749ddf4. Needs rewrite as SwiftSyntax rule.

**What it did:** Simplify generic where clauses (e.g. move constraints from `where` clause to conformance list where possible).

Original at `Sources/Swiftiomatic/Rules/Redundancy/Types/SimplifyGenericConstraints.swift` (749ddf4^).

- [ ] Rewrite as SwiftSyntaxCorrectableRule
- [ ] Add tests
- [ ] Register in RuleRegistry
