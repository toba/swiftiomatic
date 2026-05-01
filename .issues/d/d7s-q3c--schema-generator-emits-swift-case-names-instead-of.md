---
# d7s-q3c
title: Schema generator emits Swift case names instead of raw values for enum properties
status: completed
type: bug
priority: normal
created_at: 2026-05-01T19:48:20Z
updated_at: 2026-05-01T19:53:42Z
sync:
    github:
        issue_number: "609"
        synced_at: "2026-05-01T19:54:42Z"
---

RuleCollector.extractEnumCases returns element.name.text, ignoring rawValue. Result: schema for sortGetSetAccessors.order lists getSet/setGet but actual JSON requires get_set/set_get. Same bug affects default and description text.



## Summary of Changes

`RuleCollector.extractEnumCases` now returns `(name: String, rawValue: String)` pairs instead of just identifiers, so the schema generator emits the serialized raw value (e.g. `get_set`) for both the `enum` array and `default`. Updated the two consumers — `schemaNode`/`schemaNodeFromType` for config-struct enums and `detectValueType` for layout-rule enums — to translate the Swift case identifier captured from the initializer into the matching raw value.

Also regenerated `schema.json` and `ConfigurationSchema+Generated.swift`.

Added regression test `enumPropertiesUseRawValuesNotCaseNames` in `ConfigurationSchemaTests`.
