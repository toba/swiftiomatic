---
# ck1-esx
title: Adopt typed ViolationMessage pattern
status: completed
type: feature
priority: normal
created_at: 2026-03-02T22:31:48Z
updated_at: 2026-03-02T22:44:32Z
sync:
    github:
        issue_number: "136"
        synced_at: "2026-03-02T23:47:34Z"
---

Implement compile-time-safe ViolationMessage type (ExpressibleByStringInterpolation) to replace free-form String? reasons in violations.

- [x] Define ViolationMessage type
- [x] Update SyntaxViolation to accept both String and ViolationMessage
- [x] Update RuleViolation to consume ViolationMessage
- [x] Update SwiftSyntaxRule makeViolation plumbing
- [x] Migrate pilot batch of rules to typed messages
- [x] Update tests for migrated rules
- [x] Build and test


## Summary of Changes

Introduced `ViolationMessage` type conforming to `ExpressibleByStringInterpolation` for compile-time-safe violation reasons. Updated `SyntaxViolation.reason` from `String?` to `ViolationMessage?` and `RuleViolation.reason` from `String` to `ViolationMessage`. Both types retain backward-compatible `reason: String?` initializers for incremental migration. Migrated 7 pilot rules (TypedThrowsRule, ReduceBooleanRule, FireAndForgetTaskRule, DeadSymbolsRule, NestingRule, ModifierOrderRule, SingleTestClassRule) to use typed `fileprivate static` factory methods on `ViolationMessage`. All 4387 tests pass.
