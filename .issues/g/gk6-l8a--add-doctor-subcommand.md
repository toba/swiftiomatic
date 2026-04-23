---
# gk6-l8a
title: Add doctor subcommand
status: completed
type: feature
priority: normal
created_at: 2026-04-23T04:51:20Z
updated_at: 2026-04-23T05:14:19Z
sync:
    github:
        issue_number: "326"
        synced_at: "2026-04-23T05:30:22Z"
---

Add `sm doctor` CLI subcommand that validates `swiftiomatic.json` at two levels:
1. JSON Schema validation (unknown keys, wrong types, bad enum values)
2. Full `Configuration` parsing (semantic issues)

## Tasks
- [x] Fix schema generator for rule-specific properties
- [x] Add JSON Schema validator (adapted from kylef/JSONSchema.swift)
- [x] Embed schema for runtime access
- [x] Create Doctor subcommand
- [x] Register subcommand
- [x] Build and verify


## Summary of Changes

Added `sm doctor` subcommand that validates `swiftiomatic.json` in two stages:
1. JSON Schema validation against the embedded schema (catches unknown keys, wrong types, bad enum values)
2. Full `Configuration` parsing (catches semantic issues like unsupported versions)

Also fixed the schema generator:
- Removed `additionalProperties: false` from `$defs/ruleBase` and `$defs/lintOnlyBase` so rules with extra config properties (like `sortOrder`, `placement`, `words`) pass validation
- Fixed layout settings to use correct JSON types (boolean, integer) instead of all being `string`
- Moved `unit` (indentation) to use `oneOf` schema within its group
- Added `ConfigurationSchema+Generated.swift` to embed schema at runtime

New files:
- `Sources/SwiftiomaticKit/Configuration/SchemaValidator.swift`
- `Sources/Swiftiomatic/Subcommands/Doctor.swift`
- `Sources/GeneratorKit/ConfigurationSchemaSwiftGenerator.swift`
