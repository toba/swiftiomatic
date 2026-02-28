---
# n7w-9e7
title: 'Swift review: Rules/ directory cleanup and modernization'
status: completed
type: task
priority: normal
created_at: 2026-02-28T21:33:58Z
updated_at: 2026-02-28T22:21:57Z
---

Swift review findings for `Sources/Swiftiomatic/Rules/` — formatting, naming, duplication, typed throws, and dead code.

## Formatting & Linting

- [x] Fix `force_try` error in `RuleConfigurations/FileHeaderConfiguration.swift:23`
- [x] Fix `legacy_multiple` in `Format/NumberFormatting.swift:113` — use `isMultiple(of:)`
- [x] Fix 10 `pattern_matching_keywords` warnings (ModifierOrderRule, SyntacticSugarRule, NoGuardInTests, RedundantClosure, WrapMultilineFunctionChains)
- [x] Fix 7 `for_where` warnings (SortedEnumCasesRule, ModifiersOnSameLine, RedundantAsync, MarkTypes, OpaqueGenericParameters, OrganizeDeclarations, ConcurrencyModernizationRule)
- [x] Fix 2 `multiline_parameters` warnings (RedundantFileprivate, UnusedArguments)

## Shared Functionality — Configuration Boilerplate (~1,700 lines)

76/81 RuleConfiguration files have identical 5-phase `apply(configuration: Any)` bodies.

- [x] Delete Phase 1 key backfill guards (`if $prop.key.isEmpty`) — dead code, keys set at init (~136 lines across 76 files)
- [x] Extract `applySeverityIfPresent(_:)` helper on `SeverityBasedRuleConfiguration` (~350 lines across 70 files)
- [x] Extract `warnAboutUnknownKeys(in:)` on `RuleConfiguration` (~300 lines across 76 files)
- [x] Add default `apply(configuration:)` on `RuleConfiguration` via Mirror (precedent: `RuleConfigurationDescription.from(configuration:)`) — eliminates remaining per-property dispatch boilerplate; 5 outliers override

## Any Elimination

- [x] Change `RuleConfiguration.apply(configuration: Any)` signature to `apply(configuration: [String: Any])` — normalize bare `String` input at the YAML loader call site
- [x] Remove `@unchecked Sendable` from `TypeSafety/ArrayInitRule.swift:3` — struct with only Sendable properties, compiler can verify
- [x] Add explanatory comment on `RuleRegistry.swift:5` `State: @unchecked Sendable` — justified workaround for `any Rule.Type` metatype limitation

## Typed Throws

- [x] Narrow `ControlFlow/ExplicitSelfRule.swift:92` `allCursorInfo(...)` to `throws(Request.Error)`
- [x] Narrow `ControlFlow/ExplicitSelfRule.swift:148` `binaryOffsets(...)` to `throws(Request.Error)`

## Naming — Renames

- [x] `RulesFilter` → `RuleFilter` (plural inconsistency with `Rule*` family) — `RulesFilter.swift:1`
- [x] `getRules(excluding:)` → `rules(excluding:)` (drop `get` prefix per API Guidelines) — `RulesFilter.swift:18`
- [x] `RuleDeduplication` → `DiagnosticDeduplicator` (operates on `[Diagnostic]`, not rules) — `RuleDeduplication.swift:5`
- [x] `RuleLoader` → `RuleResolver` (filters+instantiates, doesn't load from disk) — `RuleLoader.swift:4`
- [x] `SourceKitFreeRule` → `SyntaxOnlyRule` (positive capability > non-standard `-Free` suffix) — `Rule.swift:274`
- [x] `AnyCollectingRule` → `CollectingRuleMarker` (`Any` prefix reserved for type-erased boxes) — `CollectingRule.swift:2`

## Naming — File-Level

- [x] Fix typo `isNotificationCenterDettachmentCall` → `isNotificationCenterDetachmentCall` — `Frameworks/NotificationCenterDetachmentRule.swift:25,44`
- [x] Consolidate deprecated `Format/SortedImports.swift` alias into `Format/SortImports.swift` and delete the file

## Naming — Optional (Low Priority)

- [x] `ViolationsSyntaxVisitor` → `ViolationCollectingVisitor` → `ViolationCollectingVisitor`
- [x] `ViolationsSyntaxRewriter` → `ViolationCollectingRewriter` → `ViolationCollectingRewriter`

## Agent Review

- [x] Audit `RuleConfigurations/TypeBodyLengthConfiguration.swift` — `TypeBodyLengthCheckType: CaseIterable` but `.allCases` not found in module; verify if consumed elsewhere or dead conformance


## Summary of Changes

All items completed across ~300 files (~1,200 lines removed):

- **Formatting**: Fixed force_try, legacy_multiple, 10 pattern_matching_keywords, 7 for_where, 2 multiline_parameters
- **Configuration boilerplate**: Deleted dead key-backfill guards, extracted applySeverityIfPresent and warnAboutUnknownKeys helpers, changed signature to [String: Any]
- **Any elimination**: Normalized config signature, removed unnecessary @unchecked Sendable, added explanatory comment
- **Typed throws**: Narrowed two ExplicitSelfRule functions to throws(Request.Error)
- **Renames**: RulesFilter→RuleFilter, getRules→rules, RuleDeduplication→DiagnosticDeduplicator, RuleLoader→RuleResolver, SourceKitFreeRule→SyntaxOnlyRule, AnyCollectingRule→CollectingRuleMarker, ViolationsSyntaxVisitor→ViolationCollectingVisitor, ViolationsSyntaxRewriter→ViolationCollectingRewriter
- **File-level**: Fixed detachment typo, consolidated SortedImports.swift into SortImports.swift
- **Audit**: TypeBodyLengthCheckType CaseIterable confirmed used by AcceptableByConfigurationElement
