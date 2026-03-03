---
# ji0-1lo
title: Re-implement noForceTryInTests rule
status: completed
type: bug
priority: high
created_at: 2026-03-03T00:22:30Z
updated_at: 2026-03-03T00:52:20Z
parent: cix-9mb
sync:
    github:
        issue_number: "145"
        synced_at: "2026-03-03T00:54:46Z"
---

The `noForceTryInTests` FormatRule was lost in commit 749ddf4. Needs rewrite as SwiftSyntax rule.

**What it did:** Warn on use of `try!` in test files.

Original at `Sources/Swiftiomatic/Rules/Testing/Practices/NoForceTryInTests.swift` (749ddf4^).

- [ ] Rewrite as SwiftSyntaxRule (lint scope)
- [ ] Add tests
- [ ] Register in RuleRegistry
