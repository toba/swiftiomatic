---
# lre-ksc
title: 'schema.json: string properties without type annotation are skipped'
status: completed
type: bug
priority: normal
created_at: 2026-05-01T01:36:38Z
updated_at: 2026-05-01T01:42:25Z
sync:
    github:
        issue_number: "596"
        synced_at: "2026-05-01T01:58:48Z"
---

ExpiringTodoConfiguration's `dateFormat`, `dateDelimitersOpening`, `dateDelimitersClosing`, and `dateSeparator` are missing from the generated schema.json. They are declared as `package var dateFormat = "MM/dd/yyyy"` (no type annotation), and `RuleCollector.schemaNode` has no branch for `StringLiteralExprSyntax` when inferring from initializers — only Int, Bool, and enum cases are handled. String-typed properties without explicit `: String` annotations fall through and are silently dropped.

## Tasks

- [x] Add failing test asserting `dateFormat` etc. appear in schema for `expiringTodo`
- [x] Add `StringLiteralExprSyntax` branch in `RuleCollector.schemaNode`
- [x] Verify full test suite passes

## Summary of Changes

- `Sources/GeneratorKit/RuleCollector.swift` — added `StringLiteralExprSyntax` branch in `schemaNode` for properties without type annotation; extracts the literal as the schema default.
- `Sources/GeneratorKit/JSONSchemaNode.swift` — added `string(description:defaultValue:)` overload.
- `Sources/GeneratorKit/ConfigurationSchemaSwiftGenerator.swift` — split `sm:ignore` directives so they attach to the right node under the new node-scoped semantics: `fileLength` above `import`, `typeBodyLength, closureBodyLength` directly above the enum.
- `Tests/SwiftiomaticTests/Utilities/ConfigurationSchemaTests.swift` — added regression test covering `dateFormat`, `dateDelimitersOpening`, `dateDelimitersClosing`, `dateSeparator`.
- Regenerated `schema.json` and `Sources/SwiftiomaticKit/Generated/ConfigurationSchema+Generated.swift`.

Verified: ConfigurationSchemaTests pass (5/5). Full suite: 3135 pass; 3 pre-existing unrelated ternary-wrap failures.
