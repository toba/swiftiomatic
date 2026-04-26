---
# hup-eta
title: schema.json missing severity properties on lint-only rules with Lint-typed config
status: completed
type: bug
priority: normal
created_at: 2026-04-26T17:13:35Z
updated_at: 2026-04-26T17:17:45Z
sync:
    github:
        issue_number: "450"
        synced_at: "2026-04-26T18:08:48Z"
---

ExpiringTodo's config struct has approachingExpirySeverity, expiredSeverity, badFormattingSeverity — all typed Lint. The schema generator's schemaNodeFromType only recognizes enum types declared in the same file, so Lint-typed properties silently disappear from schema.json. IDE flags them as unknown even though Doctor/decoding accepts them.

- [x] Add a test that schema.json has approachingExpirySeverity etc.
- [x] Teach RuleCollector.schemaNodeFromType to map type name 'Lint' to the same enum used by the base 'lint' property
- [x] Regenerate schema.json



## Summary of Changes

- `Sources/GeneratorKit/RuleCollector.swift`: added a `Lint` branch in `schemaNodeFromType` that emits a `["warn","error","no"]` string enum, using the property's initializer case as default.
- `Tests/SwiftiomaticTests/Utilities/ConfigurationSchemaTests.swift`: new test asserting `expiringTodo.properties` contains `approachingExpirySeverity`, `expiredSeverity`, `badFormattingSeverity` with correct enum values.
- `schema.json`: regenerated via `swift run Generator`. Three severity properties now appear under `expiringTodo.properties` (and again under the `comments` group), so the IDE no longer flags them as not allowed.

All 4 ConfigurationSchemaTests pass.
