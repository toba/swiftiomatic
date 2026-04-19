---
# rcc-z52
title: Convert code generator to SPM build tool plugin
status: completed
type: feature
priority: normal
created_at: 2026-04-19T17:27:58Z
updated_at: 2026-04-19T18:15:16Z
---

Convert the manual `swift run generate-swiftiomatic` step into an SPM build tool plugin so generated files stay in sync automatically on every build. Eliminates the "second place to maintain paths and type names" problem.

## Background

swift-format tried this (swiftlang/swift-format#458) — merged then reverted due to SPM plugin bugs on Windows CI. We're macOS-only, so those issues don't apply.

Currently `Generator` (executable) + `GeneratorKit` (library) scan rule/setting source files and write 4 generated files. This runs out-of-band; forgetting to run it after adding or renaming a rule silently breaks the build.

## Constraints

### Circular dependency
`GeneratorKit` depends on `SwiftiomaticKit` because `ConfigurationSchemaGenerator` imports it for `LayoutRegistry` and `IndentationSetting` (runtime type access for schema generation). A build tool plugin's executable **cannot** depend on the target it generates code for. This dependency must be broken first.

### Plugin type
SPM offers two plugin capabilities:
- `.buildCommand` — runs when inputs change, writes to plugin work directory (not source dirs)
- `.prebuildCommand` — runs before every build, can write to source dirs

Since the generated files live in `Sources/SwiftiomaticKit/Generated/`, `.prebuildCommand` is the right fit. But `.prebuildCommand` runs on *every* build, so the generator should skip writing if content hasn't changed (already does this via content comparison).

### Path resolution
`GeneratePaths.swift` uses `#filePath` to locate the source tree. Plugins receive paths via `context.package.directory` and target source directories from the plugin context API. `GeneratePaths` must be refactored to accept injected paths.

### schema.json
`schema.json` outputs to the package root, outside any target's source directory. This needs special handling — either generate it alongside the Swift files and copy it, or keep schema generation as a separate command plugin.

## Child Issues

1. **su3-lef** — Break GeneratorKit → SwiftiomaticKit circular dependency
2. **ugx-hol** — Refactor GeneratePaths to accept injected base paths
3. **y40-fgh** — Create SPM build tool plugin target (blocked by 1, 2)
4. **tea-3ch** — Handle schema.json output location
5. **qvv-k5b** — Remove standalone Generator executable target (blocked by 3)



## Summary of Changes

Converted the manual `swift run generate-swiftiomatic` step into an SPM build tool plugin. All 5 child issues completed:

1. **su3-lef** — Broke GeneratorKit → SwiftiomaticKit circular dependency by enriching DetectedSetting with AST-scanned metadata
2. **ugx-hol** — Refactored GeneratePaths from enum to struct with injected base paths
3. **y40-fgh** — Created GenerateCode build tool plugin with .buildCommand
4. **tea-3ch** — Kept schema.json as manual step (`swift run Generator`); plugin passes `--skip-schema`
5. **qvv-k5b** — Kept Generator executable (plugin dependency + schema generation)

Additional Swift best practice improvements applied:
- Unified duplicate `extractCustomKey`/`extractDescription` into single `extractStringLiteral(named:from:)`
- Extracted shared directory scanning into `enumerateSwiftStatements(in:filter:body:)`
- Modernized URL APIs: `appendingPathComponent` → `appending(path:)`
- Fixed misleading parameter name in `optionName(for:)`
- Updated CLAUDE.md code generation documentation
