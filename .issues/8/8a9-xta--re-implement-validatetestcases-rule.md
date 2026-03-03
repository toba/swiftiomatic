---
# 8a9-xta
title: Re-implement validateTestCases rule
status: completed
type: bug
priority: high
created_at: 2026-03-03T00:22:30Z
updated_at: 2026-03-03T00:52:20Z
parent: cix-9mb
sync:
    github:
        issue_number: "149"
        synced_at: "2026-03-03T00:54:46Z"
---

The `validateTestCases` FormatRule was lost in commit 749ddf4. Needs rewrite as SwiftSyntax rule.

**What it did:** Validate test case structure (e.g. test methods start with `test`, proper inheritance).

Original at `Sources/Swiftiomatic/Rules/Testing/Practices/ValidateTestCases.swift` (749ddf4^).

- [ ] Rewrite as SwiftSyntaxRule (lint scope)
- [ ] Add tests
- [ ] Register in RuleRegistry
