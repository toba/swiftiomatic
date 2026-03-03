---
# ept-0lr
title: Re-implement noGuardInTests rule
status: completed
type: bug
priority: high
created_at: 2026-03-03T00:22:30Z
updated_at: 2026-03-03T00:52:20Z
parent: cix-9mb
sync:
    github:
        issue_number: "157"
        synced_at: "2026-03-03T00:54:48Z"
---

The `noGuardInTests` FormatRule was lost in commit 749ddf4. Needs rewrite as SwiftSyntax rule.

**What it did:** Warn on use of `guard` in test methods (prefer `#require` or `XCTUnwrap`).

Original at `Sources/Swiftiomatic/Rules/Testing/Practices/NoGuardInTests.swift` (749ddf4^).

- [ ] Rewrite as SwiftSyntaxRule (lint scope)
- [ ] Add tests
- [ ] Register in RuleRegistry
