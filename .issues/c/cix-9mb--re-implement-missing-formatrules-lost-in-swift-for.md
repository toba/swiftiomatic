---
# cix-9mb
title: Re-implement missing FormatRules lost in swift-format migration
status: completed
type: epic
priority: high
created_at: 2026-03-03T00:23:10Z
updated_at: 2026-03-03T00:52:32Z
sync:
    github:
        issue_number: "144"
        synced_at: "2026-03-03T00:54:44Z"
---

13 FormatRule implementations were lost in commit 749ddf4 when the token-based format engine was replaced with swift-format. These rules had no SwiftSyntax equivalent and were not covered by swift-format's pretty-printer. Each needs to be rewritten as a SwiftSyntax rule.

## Rules

- [x] assertionFailures — convert `assert(false)` to `assertionFailure()`
- [x] genericExtensions — prefer generic extensions over type constraints
- [x] initCoderUnavailable — add `@available(*, unavailable)` to `init(coder:)`
- [x] linebreakAtEndOfFile — already covered by TrailingNewlineRule — ensure files end with exactly one trailing newline
- [x] noForceTryInTests — warn on `try!` in test files
- [x] noForceUnwrapInTests — warn on `!` unwraps in test files
- [x] noGuardInTests — warn on `guard` in tests (prefer `#require`)
- [x] redundantLetError — covered by UntypedErrorInCatchRule — remove `let error` from catch clauses
- [x] redundantRawValues — remove redundant String enum raw values
- [x] simplifyGenericConstraints — simplify generic where clauses
- [x] testSuiteAccessControl — covered by TestCaseAccessibilityRule — test class access control
- [x] throwingTests — deprecated alias for noForceTryInTests — test function throw annotations
- [x] validateTestCases — validate test case structure


## Summary of Changes
All 13 rules re-implemented or mapped to existing rules:
- **New rules**: assertionFailures, redundantRawValues, initCoderUnavailable, noForceTryInTests, noForceUnwrapInTests, noGuardInTests, validateTestCases, genericExtensions, simplifyGenericConstraints
- **Already covered**: linebreakAtEndOfFile (TrailingNewlineRule), throwingTests (deprecated alias), redundantLetError (UntypedErrorInCatchRule), testSuiteAccessControl (TestCaseAccessibilityRule)
- Added deprecated aliases for backward compatibility
