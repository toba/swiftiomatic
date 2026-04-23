---
# y40-fgh
title: Create SPM build tool plugin target
status: completed
type: task
priority: normal
created_at: 2026-04-19T17:32:03Z
updated_at: 2026-04-19T18:05:51Z
parent: rcc-z52
blocked_by:
    - su3-lef
    - ugx-hol
sync:
    github:
        issue_number: "352"
        synced_at: "2026-04-23T05:30:27Z"
---

Add a `.plugin` target to Package.swift that runs the generator automatically before each build.

- [x] Add `init(packageRoot:outputDirectory:)` to `GeneratePaths` for split input/output paths
- [x] Add content comparison to `FileGenerator.generateFile(at:)` to skip unchanged writes
- [x] Update `Generator/main.swift` to accept CLI args: `<package-root> <output-dir> [--skip-schema]`
- [x] Create `Plugins/GeneratePlugin/plugin.swift` with `BuildToolPlugin` + `.buildCommand`
- [x] Add `.plugin(name: "GenerateCode", capability: .buildTool())` to Package.swift
- [x] Apply plugin to `SwiftiomaticKit` target, exclude `Generated/` from source compilation
- [x] Verify generated files are produced on clean build


## Summary of Changes

Added SPM build tool plugin that automatically runs the code generator before each build. Key changes:

- `GeneratePaths`: new `init(packageRoot:outputDirectory:)` separates input scanning from output paths
- `FileGenerator`: content comparison skips unchanged writes (avoids unnecessary recompilation), best-effort directory creation for sandbox compatibility
- `Generator/main.swift`: accepts optional `<package-root> <output-dir> [--skip-schema]` CLI args; zero-arg mode preserved for backward compat
- `Plugins/GeneratePlugin/plugin.swift`: `BuildToolPlugin` returning `.buildCommand` with explicit input/output files
- `Package.swift`: new `GenerateCode` plugin target applied to `SwiftiomaticKit`; `Generated/` excluded from source compilation

Note: used `.buildCommand` (not `.prebuildCommand`) because SPM prebuild commands cannot use executables built from source. Plugin name avoids spaces to prevent path encoding issues.
