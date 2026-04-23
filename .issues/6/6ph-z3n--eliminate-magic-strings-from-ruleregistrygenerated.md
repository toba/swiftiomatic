---
# 6ph-z3n
title: Eliminate magic strings from RuleRegistry+Generated.swift
status: completed
type: task
priority: normal
created_at: 2026-04-18T22:47:38Z
updated_at: 2026-04-18T23:16:05Z
sync:
    github:
        issue_number: "339"
        synced_at: "2026-04-23T05:30:24Z"
---

Refactor RuleRegistry+Generated.swift to use type arrays instead of string-keyed dictionaries.

- [x] Simplify generator to emit only `allSettingTypes` + `allRuleTypes` arrays
- [x] Create non-generated RuleRegistry.swift with derived `rules`, `ruleNameCache`, `groupRules`, `groupManagedRules`
- [x] Simplify `groupRules` type from `[(String, String)]` to `[String]`
- [x] Update Configuration.swift consumers
- [x] Context.swift: kept `ruleNameCache` lookup (generic dispatch doesn't vtable-dispatch class var)
- [x] Test helpers: kept `ruleNameCache` lookup (same reason)
- [x] Regenerate and build — all tests pass



## Summary of Changes

Eliminated all magic strings from `RuleRegistry+Generated.swift`. The generated file now contains only two type arrays (`allSettingTypes` and `allRuleTypes`). All metadata (rules dict, name cache, group rules) is derived at runtime in a new `RuleRegistry.swift` extension.

Added `class var key/group/defaultHandling` to `SyntaxFormatRule` and `SyntaxLintRule` base classes, and changed ~120 subclass overrides from `static let` to `override class var` to enable correct vtable dispatch through existentials.

Discovered Swift limitation: `class var` vtable dispatch works through existentials (`any Rule.Type`) but NOT through generic constraints (`<R: Rule>`). The `ruleNameCache` remains necessary for generic-context lookups in `Context.swift`.
