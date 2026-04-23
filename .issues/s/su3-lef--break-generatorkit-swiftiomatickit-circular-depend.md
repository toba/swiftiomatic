---
# su3-lef
title: Break GeneratorKit → SwiftiomaticKit circular dependency
status: completed
type: task
priority: normal
created_at: 2026-04-19T17:31:45Z
updated_at: 2026-04-19T17:45:11Z
parent: rcc-z52
sync:
    github:
        issue_number: "351"
        synced_at: "2026-04-23T05:30:27Z"
---

`ConfigurationSchemaGenerator` imports `SwiftiomaticKit` for `LayoutRegistry.rootRules`, `LayoutRegistry.rules(in:)`, and `IndentationSetting`. This creates a circular dependency that blocks the build tool plugin.

Options:
- Move `LayoutRegistry` enumeration to AST-based scanning (like rules already work)
- Or extract the needed types (`LayoutRegistry`, `IndentationSetting`) to `ConfigurationKit`

## Plan

1. Enrich `DetectedSetting` in `ConfigurableCollector.swift` with `customKey`, `description`, `group`, and computed `settingKey` — mirroring `DetectedRule`
2. Add `extractDescription` helper (same pattern as existing `extractCustomKey`)
3. Update `detectedSetting(at:)` to extract all metadata from struct members
4. Replace `LayoutRegistry` usage in `ConfigurationSchemaGenerator.swift` with `collector.allSettings` filtered by group
5. Replace `IndentationSetting.description` with collector lookup by key `"unit"`
6. Remove `import SwiftiomaticKit` from `ConfigurationSchemaGenerator.swift`
7. Remove `"SwiftiomaticKit"` from `GeneratorKit` deps in `Package.swift`

## Checklist

- [x] Enrich `DetectedSetting` with `customKey`, `description`, `group`
- [x] Add `extractDescription` static helper
- [x] Update `detectedSetting(at:)` to extract metadata
- [x] Replace `LayoutRegistry` in `rootSettingsSchema()`
- [x] Replace `LayoutRegistry` in `groupSchemas()`
- [x] Remove `import SwiftiomaticKit`
- [x] Remove `SwiftiomaticKit` from Package.swift
- [x] Verify build passes


## Summary of Changes

Enriched `DetectedSetting` with `customKey`, `description`, and `group` fields (mirroring `DetectedRule`). Added `extractDescription` AST helper. Updated `ConfigurationSchemaGenerator` to use `collector.allSettings` instead of `LayoutRegistry`/`IndentationSetting`. Removed `import SwiftiomaticKit` and the Package.swift dependency. Schema output is identical, build and tests pass.
