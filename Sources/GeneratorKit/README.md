# Generators

Build-time code generation that keeps pipelines, registries, and documentation in sync with the rule implementations.

## What It Does

Scans all rule types in `Sources/Swiftiomatic/Rules/`, extracts their metadata (name, description, visited syntax nodes, opt-in status), and generates source files that would be tedious and error-prone to maintain by hand.

## Generated Outputs

| Generator | Output | Purpose |
|---|---|---|
| `PipelineGenerator` | `Pipelines+Generated.swift` | `visit()` dispatchers for `LintPipeline` and `FormatPipeline.rewrite()` |
| `RuleRegistryGenerator` | `RuleRegistry+Generated.swift` | Default rule enablements derived from `isOptIn` |
| `RuleNameCacheGenerator` | `RuleNameCache+Generated.swift` | `ObjectIdentifier` to rule name mapping |
| `ConfigurationSchemaGenerator` | JSON Schema | Config file validation schema |
| `RuleDocumentationGenerator` | Markdown docs | Rule reference documentation |

## Key Files

- **RuleCollector.swift** -- discovers rule source files, parses them, and extracts metadata.
- **FileGenerator.swift** -- base utility for writing generated files to disk.
- **DocumentationCommentText.swift** -- extracts doc comments from rule source for documentation generation.
- **Syntax+Convenience.swift** -- swift-syntax helpers used during rule introspection.
- **JSONSchemaNode.swift** -- JSON Schema AST for config schema generation.

## Where It Fits

Used exclusively by the `generate-swiftiomatic` build tool. Run via `swift run generate-swiftiomatic` to regenerate the `*+Generated.swift` files in `Sources/SwiftiomaticKit/Syntax/`. Never edit those generated files directly -- modify the generators or the rules instead.
