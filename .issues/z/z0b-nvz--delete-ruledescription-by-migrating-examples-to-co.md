---
# z0b-nvz
title: Delete RuleDescription by migrating examples to Configuration types
status: in-progress
type: task
priority: normal
created_at: 2026-03-01T23:57:31Z
updated_at: 2026-03-02T01:05:34Z
---

RuleDescription is no longer part of the Rule protocol (removed in 55b-kur Task 7), but the struct itself still exists as a container for test examples. A default `description` implementation synthesizes from `configuration`, so rules that define their own `static let description = RuleDescription(...)` override it with examples.

## Why it wasn't done in 55b-kur

~170 rules define examples using local helper functions (e.g. `testConfig(...)`, `wrapInSwitch(...)`, `operators`) that are scoped to the rule file. Moving examples to Configuration types requires also moving or restructuring those helpers so they're accessible from the Configuration file.

## Tasks

- [ ] Audit which rules use helper functions in examples vs. inline literals
- [ ] For rules with inline-only examples (~157): move examples to Configuration, remove description
- [ ] For rules with helper-dependent examples (~170): refactor helpers to be accessible from Configuration scope (e.g. move to Examples files or make them static on the Configuration type)
- [ ] Update `verifyRule` test infrastructure to accept `any RuleConfiguration` instead of `RuleDescription`
- [ ] Add `.with()` modifier support on the new type for test example overrides (~48 test files use this)
- [ ] Remove `RuleViolation(ruleDescription:)` initializer (35 call sites use `Self.description`)
- [ ] Remove default `description` implementation from Rule extension
- [ ] Delete `RuleDescription` struct



## Progress Tracking

- [x] Step 1: Create TestExamples in test support + new verifyRule overloads
- [x] Step 2: Migrate examples into Configuration types (327 rules)
- [x] Step 3: Migrate test files (generated tests + .with() tests)
- [x] Step 4: Remove RuleViolation(ruleDescription:) initializer (~40 call sites migrated)
- [ ] Step 5: Delete RuleDescription and bridge code (IN PROGRESS)


## Step 5 In-Progress State

Steps 1-4 are committed. Step 5 is partially done but NOT committed. Current uncommitted changes include:

### What's been done in Step 5 (uncommitted):
- Migrated all test files from `SomeRule.description` to `SomeRule.configuration` or `TestExamples(from:)`
- Migrated all test files using `.with()` on RuleDescription to `TestExamples(from:).with(...)`
- Moved `uncuddledDescription` examples from StatementPositionRule into StatementPositionConfiguration.UncuddledExamples
- Tests build green as of last check (`swift build --build-tests` → Build complete)

### What still needs to be done in Step 5:
1. Remove `static let description = RuleDescription(...)` from mock rules in MockRule.swift (MockRule + RuleWithLevelsMock) — the MockRule one was already removed, RuleWithLevelsMock still has it
2. Remove `static let description = RuleDescription(...)` from mock rules in CollectingRuleTests.swift, RuleFilterTests.swift, RuleTests.swift, SeverityLevelsOptionsTests.swift
3. Remove the `static var description: RuleDescription` synthesizer from Rule.swift (lines ~182-199)
4. Remove `FocusedRuleDescription` and old `verifyRule(_ ruleDescription: RuleDescription, ...)` overloads from LintTestHelpers.swift
5. Delete `Sources/Swiftiomatic/Models/RuleDescription.swift`
6. Delete `Tests/SwiftiomaticTests/Support/RuleDescription+Examples.swift`
7. Remove `String.formattedRationale` / `String.consoleRationale` extensions if unused elsewhere
8. Clean up the migration script (migrate_examples.py) — delete it
9. Verify: `grep -r 'RuleDescription' Sources/ Tests/` returns zero hits
10. Verify: all tests pass

### Key files with remaining RuleDescription references:
- Tests/SwiftiomaticTests/Support/MockRule.swift — RuleWithLevelsMock.description
- Tests/SwiftiomaticTests/Support/LintTestHelpers.swift — FocusedRuleDescription, old verifyRule overloads
- Tests/SwiftiomaticTests/Rules/Infrastructure/CollectingRuleTests.swift — 3 mock rules with RuleDescription
- Tests/SwiftiomaticTests/Rules/Infrastructure/RuleFilterTests.swift — 3 mock rules with RuleDescription
- Tests/SwiftiomaticTests/Rules/Infrastructure/RuleTests.swift — 2 mock rules with RuleDescription
- Tests/SwiftiomaticTests/Configuration/SeverityLevelsOptionsTests.swift — 1 mock rule with RuleDescription
- Sources/Swiftiomatic/Rules/Rule.swift — description synthesizer
- Sources/Swiftiomatic/Models/RuleDescription.swift — the file to delete

### Commits so far:
- 104f1e6: add TestExamples and RuleConfiguration-based verifyRule overloads
- 84bbb21: migrate examples from RuleDescription into Configuration types (327 rules)
- 19e0722: migrate generated tests and .with() tests to use configuration/TestExamples
- 0ff2507: remove RuleViolation(ruleDescription:) initializer, migrate all call sites
