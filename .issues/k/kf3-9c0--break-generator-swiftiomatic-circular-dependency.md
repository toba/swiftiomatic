---
# kf3-9c0
title: Break generator ↔ Swiftiomatic circular dependency
status: completed
type: task
priority: normal
created_at: 2026-04-18T02:18:33Z
updated_at: 2026-04-18T02:27:36Z
---

Replace runtime reflection with AST parsing in RuleCollector. Create SwiftiomaticCore shared target for ConfigGroup.

- [x] Create Sources/SwiftiomaticCore/ConfigGroup.swift
- [x] Update Sources/Swiftiomatic/API/ConfigGroup.swift to re-export
- [x] Update Package.swift (new target, rename _GenerateSwiftiomatic → Generators)
- [x] Copy DocumentationCommentText into Generators
- [x] Rewrite RuleCollector.swift — remove _typeByName reflection
- [x] Update remaining Generator imports
- [x] Update test import
- [x] Verify build and generated output


## Summary of Changes

Broke the circular dependency between the Generators target and Swiftiomatic by:

1. Created `SwiftiomaticCore` target with `ConfigGroup`, `Groupable`, `ConfigProperty`, `ConfigRepresentable`, and rule config structs — all types the generator needs that have no Swiftiomatic dependencies
2. Replaced `_typeByName()` runtime reflection in `RuleCollector` with pure SwiftSyntax AST parsing for `isOptIn` and `group`
3. Copied `DocumentationCommentText` into Generators (only depends on SwiftSyntax)
4. Updated `ConfigurationSchemaGenerator` to compute group rules from `ruleCollector` instead of `RuleRegistry`
5. Renamed target `_GenerateSwiftiomatic` → `Generators`

Generator now builds independently of Swiftiomatic. Generated output is identical.
