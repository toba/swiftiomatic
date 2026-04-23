---
# 34d-ct2
title: 'Eliminate magic strings: protocol-enforced rule/config names'
status: completed
type: task
priority: normal
created_at: 2026-04-18T01:18:11Z
updated_at: 2026-04-18T02:17:05Z
blocked_by:
    - lbt-zsc
sync:
    github:
        issue_number: "331"
        synced_at: "2026-04-23T05:30:22Z"
---

## Problem

Rule config names are duplicated as magic strings across multiple files:
- `Configuration.ruleConfigDecoders` maps string → decode closure
- `Configuration.ruleConfigEncodable(for:)` maps string → encodable value  
- `ConfigurationSchemaGenerator.ruleOptionsSchema(for:)` matches string → schema
- `Configuration.groupRules` maps string options → string rule names

These all must stay in sync manually. If a rule is renamed, each location must be updated independently.

## Design Direction

Rule-specific config structs should declare their associated rule name as a static protocol requirement (similar to how `Rule.ruleName` works). A `RuleConfig` protocol:

```swift
protocol RuleConfig: Codable, Equatable, Sendable {
  static var ruleName: String { get }
  init()
}
```

Then config registration can be driven from the types themselves rather than manual string tables:

```swift
static let ruleConfigs: [any RuleConfig.Type] = [
  FileScopedDeclarationPrivacyConfiguration.self,
  SortImportsConfiguration.self,
  // ...
]
```

The `ruleConfigDecoders`, `ruleConfigEncodable(for:)`, and schema generation would all derive from this single list.

Similarly, `ConfigGroup.groupRules` could be derived from the `Rule.group` property on each rule class rather than a separate static table — the code generator already knows each rule's group.

## Tasks

- [x] Create `ConfigRepresentable` protocol with `configProperties`
- [x] Conform existing 8 config structs + ConfigGroup
- [x] Replace `ruleConfigDecoders` and `ruleConfigEncodable(for:)` with `RuleConfigEntry`-driven lookup
- [ ] Generate `groupRules` table from rule `group` properties in code gen
- [x] Update schema generator to derive options from `ConfigRepresentable` conformances


## Summary of Changes (partial)

- Added `rulePrefix` to `ConfigGroup` for deriving short option names
- `RuleCollector` now extracts `group` from each rule type at gen time
- `RuleRegistryGenerator` generates `groupRules` and `groupManagedRules` tables
- Deleted hand-maintained `groupRules` (~50 lines) from Configuration.swift
- Configuration now reads from `RuleRegistry.groupRules` (generated)
- New `sort` and `capitalization` groups automatically populated
- Remaining: `ruleConfigDecoders` / `ruleConfigEncodable` magic strings (deferred)


## Final Summary

- `ConfigRepresentable` protocol with `configProperties: [ConfigProperty]` — both instance (enums) and static (structs)
- `ConfigProperty` struct with `Schema` enum covering bool, integer, string, stringEnum, stringArray
- All 8 rule config structs conform with `ruleName` and `configProperties`
- `ConfigGroup` conforms — each case returns its non-rule settings
- `RuleConfigEntry` replaces magic-string decoder/encoder dicts
- `Configuration.ruleConfigSchemas` exposed via `@_spi(Internal)`
- Schema generator's `ruleOptionsSchema` and `groupSchemas` now fully driven by `ConfigRepresentable` + `RuleRegistry`
- Zero magic strings remain in schema generation or config encoding/decoding
