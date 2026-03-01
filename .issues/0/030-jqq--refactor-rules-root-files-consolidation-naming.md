---
# 030-jqq
title: 'Refactor Rules/ root files: consolidation & naming'
status: completed
type: task
priority: normal
created_at: 2026-02-28T19:16:03Z
updated_at: 2026-02-28T19:19:47Z
sync:
    github:
        issue_number: "21"
        synced_at: "2026-03-01T01:01:34Z"
---

Collapse AllRules+CoreRules+Extra into Exports.swift, merge AsyncEnrichableRule into Rule.swift, extract ReasonedRuleViolation to Models/RuleViolation.swift, move [any Rule] == from CollectingRule to Rule, remove dead ConditionallySourceKitFree protocol, rename enrichAsync→enrich


## Summary of Changes

- **Collapsed AllRules.swift + CoreRules.swift + Extra.swift → Exports.swift**: Inlined the full 262-entry rule type list directly, eliminating 3 separate files and constants
- **Moved `[any Rule] ==` from CollectingRule.swift → Rule.swift**: The operator was unrelated to collecting; now lives with the Rule protocol
- **Extracted ReasonedRuleViolation → Models/RuleViolation.swift**: 83-line domain model (+ nested ViolationCorrection + array extensions) moved out of SwiftSyntaxRule.swift
- **Merged AsyncEnrichableRule.swift → Rule.swift**: Single thin protocol now lives alongside OptInRule, CorrectableRule, AnalyzerRule
- **Removed dead ConditionallySourceKitFree protocol**: Zero real conformers; removed from Rule.swift, Request+SafeSend.swift, RuleDocumentation.swift; deleted test file
- **Renamed enrichAsync → enrich**: Updated protocol decl, Analyzer.swift, and 4 conformer extensions (AnyEliminationRule, TypedThrowsRule, NamingHeuristicsRule, ConcurrencyModernizationRule)

Files deleted (5): AllRules.swift, Extra.swift, CoreRules.swift, AsyncEnrichableRule.swift, ConditionallySourceKitFreeTests.swift
Files created (1): Models/RuleViolation.swift
Files modified (8): Exports.swift, Rule.swift, CollectingRule.swift, SwiftSyntaxRule.swift, Request+SafeSend.swift, RuleDocumentation.swift, Analyzer.swift, + 4 rule conformers
