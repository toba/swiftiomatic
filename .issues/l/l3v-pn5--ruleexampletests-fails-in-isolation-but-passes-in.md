---
# l3v-pn5
title: RuleExampleTests fails in isolation but passes in full suite
status: ready
type: bug
priority: high
created_at: 2026-04-12T02:50:24Z
updated_at: 2026-04-12T03:11:37Z
sync:
    github:
        issue_number: "206"
        synced_at: "2026-04-12T03:13:32Z"
---

## Problem

`RuleExampleTests` consistently fails when run in isolation via `swift_package_test --filter RuleExampleTests` but passes when the full test suite runs (493 passed, 0 failed).

### Output when filtered

```
Tests failed (2 passed, 1 failed)

Failures:
  Rule examples validate — Issue recorded: triggeringExample did not violate: (LintTestHelpers.swift:649)
```

### What we know

- **Full suite passes**: 493 passed, 0 failed
- **Filtered fails**: `--filter RuleExampleTests` consistently 2 passed, 1 failed
- **Individual rules all pass**: tested foundation_modernization, swiftui_view_anti_patterns, prefer_module_selector, prefer_c_attribute, prefer_specialize_attribute, redundant_main_actor_view, swiftui_superseded_patterns, statement_position, identifier_name, plus alphabet-prefix filters (verifyExamples/a, verifyExamples/s) — all pass
- **"2 passed, 1 failed" count is suspicious** with ~300 testable rules — suggests MCP tool may be miscounting parameterized test sub-cases, or the failure is in test setup/teardown not a specific rule
- The `.rulesRegistered` trait calls `_testSetup` which runs `RuleRegistry.registerAllRulesOnce()` and `disableSourceKitForTesting()`
- `RuleCase.testable` also calls `_ = _testSetup` before filtering rules

### Hypotheses

1. **Test interaction**: running all ~300 rules in one parameterized test causes shared state corruption that doesn't happen individually
2. **MCP tool reporting artifact**: "2 passed, 1 failed" may miscount `@Test(arguments:)` sub-cases — actual count should be ~290, not 3
3. **Race condition**: parameterized test arguments evaluated before trait's `provideScope` runs

### Related

- `dw7-050` in xc-mcp: swift_package_test truncates failure messages, can't identify which rule/example failed
- `i74-cb6`: previously fixed 5 test failures (StatementPositionRule, IdentifierNameRule) — those fixes are in the working tree

### Next steps

- [ ] Run tests outside MCP to see full output and actual counts
- [ ] Add debug logging to RuleExampleTests.verifyExamples that prints the rule ID before each test case
- [ ] Check if --parallel vs --no-parallel changes behavior



## Additional findings

- Added `.serialized` trait to suite — still fails. NOT a concurrency issue.
- Fixed real bugs in `lock_anti_patterns` (wrong visit order, wrong position), `async_stream_safety` (2 violations for 1 marker), `date_for_timing` (marker at wrong Date() call) — these were genuine example bugs but didn't cause the isolation failure.
- After fixing those, `balanced_xctest_lifecycle` fails next — a well-established rule with no bugs. Strongly suggests test infrastructure issue, not individual rule bugs.
- CI runs full suite, not filtered. Full suite passes with SWIFTIOMATIC_FULL_TESTS=1. This is a test-runner isolation issue, not a CI blocker.
- The `.serialized` trait remains on the suite for now (safe, doesn't hurt).
