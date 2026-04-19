---
# rcc-z52
title: Convert code generator to SPM build tool plugin
status: draft
type: feature
priority: normal
created_at: 2026-04-19T17:27:58Z
updated_at: 2026-04-19T17:29:23Z
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

## Tasks

- [ ] Break `GeneratorKit` → `SwiftiomaticKit` dependency
  - Move `LayoutRegistry` enumeration to AST-based scanning (like rules already work)
  - Or extract the needed types (`LayoutRegistry`, `IndentationSetting`) to `ConfigurationKit`
  - Verify `ConfigurationSchemaGenerator` works without `import SwiftiomaticKit`
- [ ] Refactor `GeneratePaths` to accept injected base paths instead of `#filePath`
  - Add an initializer/factory that takes a package root URL
  - Keep the `#filePath`-based paths as a convenience for the standalone executable (backward compat during migration)
- [ ] Create the build tool plugin target
  - Add `.plugin(name: "GeneratePlugin", capability: .buildCommand(...))` or `.prebuildCommand(...)` to Package.swift
  - Plugin executable reuses `GeneratorKit` with injected paths from plugin context
  - Declare input directories and output files for correct invalidation
- [ ] Handle `schema.json` output
  - Option A: generate alongside Swift files, add a post-build copy step
  - Option B: keep schema generation as a separate `.command` plugin (run manually)
  - Option C: move schema.json into `Sources/SwiftiomaticKit/Generated/` and reference from there
- [ ] Remove the standalone `Generator` executable target (or keep as convenience alias)
- [ ] Verify full build cycle: clean build, incremental build, add new rule, rename rule
- [ ] Update CLAUDE.md build instructions
