---
# efo-x3y
title: Refactor pretty-print config values as LayoutDescriptor types
status: completed
type: feature
priority: normal
created_at: 2026-04-18T18:50:07Z
updated_at: 2026-04-18T18:59:38Z
---

- [x] Create LayoutDescriptor protocol in SwiftiomaticKit (ConfigurationKit can't reference Configuration)
- [x] Create individual setting files in Layout/Settings/ with registry
- [x] Update Configuration.swift to derive allSettings from descriptors
- [x] Update Configuration+Default.swift to reference descriptor defaultValues
- [x] Update ConfigGroup.configProperties to derive from descriptors
- [x] Update ConfigurationSchemaGenerator.rootSettingsSchema() to derive from descriptors
- [x] Build and verify tests pass (2378/2378)


## Summary of Changes

Refactored ~20 pretty-print configuration values from scattered metadata across 4 files into self-describing `LayoutDescriptor` types in `Layout/Settings/`. Each setting is its own file carrying key, group, description, default value, and schema. `Configuration`, `ConfigGroup`, and `ConfigurationSchemaGenerator` now derive their data from these types.
