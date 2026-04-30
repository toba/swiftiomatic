# GeneratorKit

Build-time code generation that keeps pipelines, registries, and the configuration schema in sync with rule implementations.

## What It Does

Scans rule source files under `Sources/SwiftiomaticKit/Rules/` and `Sources/SwiftiomaticKit/Layout/`, extracts metadata via swift-syntax (rule key, group, default handling, visited node types, `static transform`/`willEnter`/`didExit` hooks, doc-comment description), and emits source files that would be tedious and error-prone to maintain by hand.

## Generated Outputs

| Generator | Output | Purpose |
|---|---|---|
| `PipelineGenerator` | `Pipelines+Generated.swift`, `CompactStageOneRewriter+Generated.swift` | `visit()` dispatchers for `LintPipeline` and the stage-1 compact rewriter |
| `ConfigurationGenerator` | `ConfigurationRegistry+Generated.swift` | Type arrays for all rules and settings |
| `ConfigurationSchemaGenerator` | `schema.json` | JSON Schema for the configuration |
| `ConfigurationSchemaSwiftGenerator` | `ConfigurationSchema+Generated.swift` | Embedded schema for runtime validation |
| `TokenStreamStubGenerator` | `TokenStream+Generated.swift` | Forwarding stubs for the `TokenStream` subclass |

## Key Files

- **`RuleCollector.swift`** -- discovers rule source files, parses them, and extracts metadata (including the doc-comment description used by the JSON schema).
- **`SwiftFileScanner.swift`** -- enumerates `.swift` files under a directory and feeds them to the collector.
- **`SyntaxVisitorOverrideCollector.swift`** -- detects `visit(_:)` overrides used by `TokenStreamStubGenerator`.
- **`FileGenerator.swift`** -- base utility for writing generated files (skips writes when content is unchanged).
- **`DocumentationCommentText.swift`** -- extracts doc comments from rule source for inclusion in the JSON schema description fields.
- **`JSONSchemaNode.swift`** -- JSON Schema AST used by `ConfigurationSchemaGenerator`.

## Where It Fits

Used exclusively by the `Generator` executable, which is invoked by the `GenerateCode` SPM build tool plugin on every build. Outputs are written to `Sources/SwiftiomaticKit/Generated/`. Run `swift run Generator` manually to regenerate the schema (the build plugin skips it by default). Never edit `*+Generated.swift` files directly -- modify the generators or the rules instead.
