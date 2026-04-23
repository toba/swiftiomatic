---
# vll-t2h
title: Rationalize rule value types
status: completed
type: feature
priority: normal
created_at: 2026-04-19T19:23:51Z
updated_at: 2026-04-23T16:03:59Z
sync:
    github:
        issue_number: "344"
        synced_at: "2026-04-23T16:14:36Z"
---

Replace RuleHandling enum with clean SyntaxRuleValue protocol system.

- [x] Foundation types: Lint enum, SyntaxRuleValue protocol, LintValue struct in ConfigurationKit
- [x] Make base classes generic: LintSyntaxRule<V>, RewriteSyntaxRule<V>
- [x] Update SyntaxRule protocol: constrain Value: SyntaxRuleValue, remove defaultHandling
- [x] Migrate all simple syntax rules to LintSyntaxRule<LintValue>
- [x] Migrate 10 complex rules: config structs conform to SyntaxRuleValue
- [x] Update Configuration storage: unify into values dict, remove rules dict + ruleConfigEntries
- [x] Update Context + Finding to use Lint instead of RuleHandling
- [x] Update code generation: collector, schema gen, pipeline gen
- [x] Delete RuleHandling.swift
- [x] Build + test (2371 passed)


## Summary of Changes

Replaced `RuleHandling` enum with `SyntaxRuleValue` protocol system. All syntax rules now have a typed Value that includes `enabled: Bool` and `lint: Lint`. Config structs for complex rules conform to `SyntaxRuleValue` directly. Auto-fix is implicit for `RewriteSyntaxRule`. Base classes are generic (`LintSyntaxRule<V>`, `RewriteSyntaxRule<V>`). Configuration storage unified into single `values` dict. Fixed latent bug where `RewritePipeline` didn't check rule enablement for root-node rules.
