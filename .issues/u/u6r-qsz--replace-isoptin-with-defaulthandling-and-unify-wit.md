---
# u6r-qsz
title: Replace isOptIn with defaultHandling and unify with LayoutDescriptor
status: completed
type: feature
priority: normal
created_at: 2026-04-18T19:04:17Z
updated_at: 2026-04-18T19:11:39Z
sync:
    github:
        issue_number: "334"
        synced_at: "2026-04-23T05:30:24Z"
---

Replace `isOptIn: Bool` on `Rule` with `defaultHandling: RuleHandling`, create shared `ConfigurableItem` protocol for both `Rule` and `LayoutDescriptor`.

- [x] Create `ConfigurableItem` protocol in ConfigurationKit
- [x] Update `Rule` protocol — remove `isOptIn`, add `defaultHandling`, conform `ConfigurableItem`
- [x] Add protocol extension defaults for `SyntaxFormatRule` (.fix) and `SyntaxLintRule` (.warning)
- [x] Update 56 rule files: `isOptIn = true` → `defaultHandling: RuleHandling = .off`
- [x] Conform `LayoutDescriptor` to `ConfigurableItem`
- [x] Update `RuleCollector` — extract `defaultHandling` instead of `isOptIn`
- [x] Update `RuleRegistryGenerator` — simplify default derivation
- [x] Update `ConfigurationSchemaGenerator` — replace `isOptIn` references
- [x] Update docs/comments
- [x] Regenerate and verify build


## Summary of Changes

Replaced `isOptIn: Bool` with `defaultHandling: RuleHandling` on the `Rule` protocol. Created `ConfigurableItem` protocol in ConfigurationKit that both `Rule` and `LayoutDescriptor` conform to, unifying the key + default + group concept. Defaults are provided via constrained protocol extensions (`where Self: SyntaxFormatRule` → `.fix`, `where Self: SyntaxLintRule` → `.warning`). Rules use `static let` to override. Generated output is identical.
