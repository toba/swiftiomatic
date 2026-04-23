---
# von-47s
title: 'Swift review: JSON encoding, decoding, schema generation, schema validation'
status: completed
type: task
priority: normal
created_at: 2026-04-23T05:34:01Z
updated_at: 2026-04-23T05:47:29Z
sync:
    github:
        issue_number: "355"
        synced_at: "2026-04-23T05:49:34Z"
---

- [x] Review JSONValue, JSONSchemaValue, JSONSchemaNode Codable implementations
- [x] Review Configuration Codable (DictEncoder, JSONFragment)
- [x] Review SchemaValidator
- [x] Review ConfigurationSchemaGenerator
- [x] Report findings


## Summary of Changes

- Unified `JSONValue` (moved to ConfigurationKit as `public`) and deleted duplicate `JSONSchemaValue` from GeneratorKit
- Replaced `DictEncoder`'s `[String: Any]` with `[String: JSONValue]` — eliminates type erasure and `JSONSerialization` round-trips
- Fixed `Configuration.Equatable` — was comparing via `String(describing:)` on `Any` dictionaries (non-deterministic), now uses `JSONValue` equality
- Eliminated `JSONFragment` — groups now encode `JSONValue.object(dict)` directly
- Reduced `asJsonString()` from 3 serialization passes to 2 (encode → inject `$schema` → encode)
- Fixed `JSONSchemaNode.items` from `[String: String]?` to `Indirect<JSONSchemaNode>?` for correct JSON Schema typing
- Fixed `Lint.init(from:)` creating two single-value containers
- Fixed 10 pre-existing test failures caused by config key mismatches after grouping refactor
- Added build artifact patterns to `.gitignore`
