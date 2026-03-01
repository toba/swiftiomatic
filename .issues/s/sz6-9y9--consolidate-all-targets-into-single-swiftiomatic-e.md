---
# sz6-9y9
title: Consolidate all targets into single Swiftiomatic executable
status: completed
type: task
priority: normal
created_at: 2026-02-27T23:58:22Z
updated_at: 2026-02-28T00:15:00Z
sync:
    github:
        issue_number: "23"
        synced_at: "2026-03-01T01:01:33Z"
---

Merge 8 targets into single executable target. Keep SwiftLintCoreMacros and DyldWarningWorkaround separate.

- [x] Move source folders into Sources/Swiftiomatic/
- [x] Update Package.swift to 4 targets
- [x] Remove all cross-module imports
- [x] Convert package → internal in Lint/Framework
- [x] Fix naming collisions  
- [x] Update test target
- [x] Build and test

## Summary of Changes

Consolidated 8 separate Swift targets into a single `Swiftiomatic` executable target.
Only `DyldWarningWorkaround` (C code) and `SwiftLintCoreMacros` (compiler plugin) remain separate.

Key changes:
- Moved Suggest/, Format/, SourceKitService/, Lint/{Core,BuiltInRules,ExtraRules,Framework} into Sources/Swiftiomatic/
- Package.swift reduced to 4 targets (from 10)
- Removed all cross-module imports (~120 files)
- Renamed colliding types: Lint Version → LintVersion, Format Category → DeclarationCategory, File → FilePath
- Renamed @main struct to SwiftiomaticCLI to avoid shadowing module name
- Removed duplicate extension methods (containsComments, hasTrailingWhitespace)
- Converted package access level → internal in Lint/Framework
- Language mode: .v5 on the single target (required by vendored Lint code)
