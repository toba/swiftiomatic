---
# 61w-ibn
title: Re-implement assertionFailures rule
status: completed
type: bug
priority: high
created_at: 2026-03-03T00:22:30Z
updated_at: 2026-03-03T00:36:02Z
parent: cix-9mb
sync:
    github:
        issue_number: "153"
        synced_at: "2026-03-03T00:54:46Z"
---

The `assertionFailures` FormatRule was lost in commit 749ddf4 when the token-based format engine was replaced with swift-format. It needs to be rewritten as a SwiftSyntax rule.

**What it did:** Convert `assert(false)` to `assertionFailure()` and `assert(false, "msg")` to `assertionFailure("msg")`.

Original implementation is in git history at `Sources/Swiftiomatic/Rules/ControlFlow/Returns/AssertionFailures.swift` (commit 749ddf4^).

- [x] Rewrite as SwiftSyntaxCorrectableRule
- [x] Add tests
- [x] Register in RuleRegistry


## Summary of Changes
Rewrote assertionFailures as SwiftSyntaxCorrectableRule. Converts assert(false)/precondition(false) to assertionFailure()/preconditionFailure() with auto-fix support.
