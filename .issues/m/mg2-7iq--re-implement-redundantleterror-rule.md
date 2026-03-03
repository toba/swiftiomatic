---
# mg2-7iq
title: Re-implement redundantLetError rule
status: completed
type: bug
priority: high
created_at: 2026-03-03T00:22:30Z
updated_at: 2026-03-03T00:52:20Z
parent: cix-9mb
sync:
    github:
        issue_number: "147"
        synced_at: "2026-03-03T00:54:46Z"
---

The `redundantLetError` FormatRule was lost in commit 749ddf4. Needs rewrite as SwiftSyntax rule.

**What it did:** Remove redundant `let error` from catch clauses (`catch let error {` -> `catch {`).

Original at `Sources/Swiftiomatic/Rules/Redundancy/Expressions/RedundantLetError.swift` (749ddf4^).

- [ ] Rewrite as SwiftSyntaxCorrectableRule
- [ ] Add tests
- [ ] Register in RuleRegistry

\n## Summary of Changes\nAlready covered by UntypedErrorInCatchRule (id: untyped_error_in_catch) which is a superset. Added 'redundant_let_error' as a deprecated alias for backward compatibility.
