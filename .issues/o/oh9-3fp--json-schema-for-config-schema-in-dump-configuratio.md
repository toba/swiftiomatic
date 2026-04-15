---
# oh9-3fp
title: JSON schema for config; $schema in dump-configuration; rename config to swiftiomatic.json
status: completed
type: feature
priority: normal
created_at: 2026-04-15T00:51:57Z
updated_at: 2026-04-15T01:07:23Z
---

- [x] Explore config structure, all rules, and rule options
- [x] Rename config file from `.swiftiomatic` to `swiftiomatic.json` (no leading dot — Xcode hides dotfiles in SPM projects)
- [x] Create a comprehensive JSON schema file describing all config options and rules
- [x] Add `$schema` reference to GitHub-hosted schema in `dump-configuration` output


## Summary of Changes

- Renamed config file from `.swiftiomatic.json` to `swiftiomatic.json` (no leading dot)
- Created `JSONSchemaNode` Codable struct and `ConfigurationSchemaGenerator` in `_GenerateSwiftiomatic`
- Schema generated at repo root as `swiftiomatic.schema.json` via `swift run generate-swiftiomatic`
- Rule descriptions sourced from `RuleCollector` DocC comments (single source of truth)
- `dump-configuration` output now includes `$schema` reference to GitHub-hosted schema
- 125 rules with descriptions, all config options with types, defaults, and enums
