---
# 6g6-n3m
title: Re-implement throwingTests rule
status: completed
type: bug
priority: high
created_at: 2026-03-03T00:22:30Z
updated_at: 2026-03-03T00:36:12Z
parent: cix-9mb
sync:
    github:
        issue_number: "151"
        synced_at: "2026-03-03T00:54:46Z"
---

The `throwingTests` FormatRule was lost in commit 749ddf4. Needs rewrite as SwiftSyntax rule.

**What it did:** Enforce/check throw annotations on test functions.

Original at `Sources/Swiftiomatic/Rules/Testing/Assertions/ThrowingTests.swift` (749ddf4^).

- [ ] Rewrite as SwiftSyntaxRule (lint scope)
- [ ] Add tests
- [ ] Register in RuleRegistry

\n## Summary of Changes\nthrowingTests was a deprecated alias for noForceTryInTests. The noForceTryInTests rule will be re-implemented (ji0-1lo).
