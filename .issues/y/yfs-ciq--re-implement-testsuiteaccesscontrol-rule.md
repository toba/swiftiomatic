---
# yfs-ciq
title: Re-implement testSuiteAccessControl rule
status: completed
type: bug
priority: high
created_at: 2026-03-03T00:22:30Z
updated_at: 2026-03-03T00:44:55Z
parent: cix-9mb
sync:
    github:
        issue_number: "148"
        synced_at: "2026-03-03T00:54:46Z"
---

The `testSuiteAccessControl` FormatRule was lost in commit 749ddf4. Needs rewrite as SwiftSyntax rule.

**What it did:** Ensure test classes/suites have correct access control.

Original at `Sources/Swiftiomatic/Rules/Testing/Practices/TestSuiteAccessControl.swift` (749ddf4^).

- [ ] Rewrite as SwiftSyntaxRule (lint scope)
- [ ] Add tests
- [ ] Register in RuleRegistry

\n## Summary of Changes\nAlready covered by existing TestCaseAccessibilityRule (id: test_case_accessibility). Added 'test_suite_access_control' as a deprecated alias.
