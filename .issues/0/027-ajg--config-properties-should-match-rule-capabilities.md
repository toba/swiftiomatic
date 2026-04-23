---
# 027-ajg
title: Config properties should match rule capabilities
status: completed
type: task
priority: normal
created_at: 2026-04-23T02:45:17Z
updated_at: 2026-04-23T02:48:50Z
sync:
    github:
        issue_number: "346"
        synced_at: "2026-04-23T05:30:25Z"
---

- [x] Create LintOnlyValue in ConfigurationKit
- [x] Change 16 lint-only rules from LintSyntaxRule<LintValue> to LintSyntaxRule<LintOnlyValue>
- [x] Update defaultValue overrides on lint-only opt-in rules
- [x] Update RuleCollector.extractIsOptIn for LintOnlyValue pattern
- [x] Update schema generator with lintOnlyBase def
- [x] Regenerate schema.json and swiftiomatic.json
- [x] Build and verify


## Summary of Changes

Created `LintOnlyValue` type in ConfigurationKit that conforms to `SyntaxRuleValue` but only encodes `lint` (no `rewrite`). Changed all 16 lint-only rules to use it. Updated schema generator with a `lintOnlyBase` def. Updated `RuleCollector.extractIsOptIn` to detect the `LintOnlyValue(lint: .no)` pattern.
