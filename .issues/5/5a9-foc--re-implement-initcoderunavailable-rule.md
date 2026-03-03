---
# 5a9-foc
title: Re-implement initCoderUnavailable rule
status: completed
type: bug
priority: high
created_at: 2026-03-03T00:22:30Z
updated_at: 2026-03-03T00:52:20Z
parent: cix-9mb
sync:
    github:
        issue_number: "150"
        synced_at: "2026-03-03T00:54:46Z"
---

The `initCoderUnavailable` FormatRule was lost in commit 749ddf4. Needs rewrite as SwiftSyntax rule.

**What it did:** Add `@available(*, unavailable)` to required `init(coder:)` implementations.

Original at `Sources/Swiftiomatic/Rules/Frameworks/UIKit/InitCoderUnavailable.swift` (749ddf4^).

- [ ] Rewrite as SwiftSyntaxCorrectableRule
- [ ] Add tests
- [ ] Register in RuleRegistry
