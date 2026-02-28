---
# kmp-lex
title: Fix 15 disabled CustomRulesTests for SuperfluousDisableCommand interaction
status: completed
type: bug
priority: normal
created_at: 2026-02-28T15:27:52Z
updated_at: 2026-02-28T17:06:07Z
---

15 tests in `Tests/SwiftiomaticTests/LintTests/Framework/CustomRulesTests.swift` are disabled with:
`.disabled("SuperfluousDisableCommand+CustomRules broken under parallel execution")`

## Affected Tests

All in the `// MARK: - superfluous_disable_command support` section:
- customRulesTriggersSuperfluousDisableCommand
- specificCustomRuleTriggersSuperfluousDisableCommand
- specificAndCustomRulesTriggersSuperfluousDisableCommand
- customRulesViolationAndViolationOfSuperfluousDisableCommand
- disablingCustomRulesDoesNotTriggerSuperfluousDisableCommand
- multipleSpecificCustomRulesTriggersSuperfluousDisableCommand
- unviolatedSpecificCustomRulesTriggersSuperfluousDisableCommand
- violatedSpecificAndGeneralCustomRulesTriggersSuperfluousDisableCommand
- superfluousDisableCommandWithMultipleCustomRules
- violatedCustomRuleDoesNotTriggerSuperfluousDisableCommand
- disableAllDoesNotTriggerSuperfluousDisableCommand
- disableAllAndDisableSpecificCustomRuleDoesNotTriggerSuperfluousDisableCommand
- nestedCustomRuleDisablesDoNotTriggerSuperfluousDisableCommand
- nestedAndOverlappingCustomRuleDisables
- superfluousDisableRuleOrder

## Root Cause

These tests exercise the interaction between `CustomRules` and `SuperfluousDisableCommandRule`. Under parallel execution (after removing `@Suite(.serialized)`), the `violations(forExample:customRules:)` helper returns 0 violations when it should return superfluous disable command violations. The custom rule violations themselves work, but the SuperfluousDisableCommand detection fails.

Likely cause: `SuperfluousDisableCommandRule` relies on shared state or ordering assumptions that break under parallel rule execution via `parallelMap` in `CollectedLinter.getStyleViolations()`.

## Additional Issue

SourceKit (sourcekitd) crashes with SIGSEGV under parallel test load. This is an external LLVM/SourceKit bug — the "PLEASE submit a bug report to llvm-project" message appears. This kills the test process with exit code 1 even when all tests pass. Consider running tests with `SWIFTLINT_DISABLE_SOURCEKIT=1` once the fatalError paths are converted to graceful degradation, or reducing test parallelism.

## TODO

- [ ] Investigate SuperfluousDisableCommandRule state management under parallel execution
- [ ] Fix the interaction and re-enable all 15 tests
- [ ] Consider whether the SourceKit SIGSEGV needs a workaround (env var, reduced parallelism)

## Summary of Changes

Resolved by removing CustomRules entirely (heb-2ie). The 15 disabled tests and the CustomRulesTests file no longer exist.
