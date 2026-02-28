---
# v20-de2
title: Remove support for analyzing Swift code earlier than 6.2
status: completed
type: task
priority: normal
created_at: 2026-02-28T00:13:29Z
updated_at: 2026-02-28T00:29:11Z
---

Swiftiomatic should only support analyzing, formatting, and linting Swift 6.2+ code. Remove all handling for earlier Swift language versions in the analysis targets.

This means:
- **Suggest module**: Remove any checks or logic that handles pre-6.2 Swift patterns (e.g. suggesting migrations TO Swift 6 features — if the code isn't already 6.2, it's out of scope)
- **Format module**: Remove SwiftFormat rules/options that only apply to pre-6.2 code (e.g. `--swiftversion` handling for older versions, rules gated on Swift version checks < 6.2)
- **Lint module**: Remove SwiftLint rules/configurations that target pre-6.2 code (e.g. deployment target checks for old versions, rules about legacy syntax that doesn't compile under 6.2)
- **CLI**: Remove any `--swift-version` flags or config options that allow selecting a version < 6.2; if a version flag remains, validate it's >= 6.2
- **Tests**: Update fixtures and test cases that use pre-6.2 syntax

## Rationale

Swiftiomatic is opinionated and forward-looking. Supporting old Swift versions adds complexity and noise. If the code being analyzed isn't Swift 6.2, it shouldn't be fed to this tool.

## TODO

- [x] Audit Suggest checks for version-gated logic (none found — already targets 6.2+)
- [x] Audit Format rules for swift version checks — removed 20+ always-true guards
- [x] Audit Lint rules for version-gated behavior — simplified 4 runtime checks
- [x] Remove or simplify CLI version flags — added Config validation (clamp to >= 6.2)
- [x] Update tests and fixtures — all 12 tests pass
- [x] Update CLAUDE.md if needed — no changes needed


## Summary of Changes

### Format Rules (~15 files)
- Removed always-true version guards (`>= "4.1"` through `>= "6.0"`) from: AnyObjectProtocol, ApplicationMain, ConditionalAssignment, EnvironmentEntry, GenericExtensions, HoistAwait, OpaqueGenericParameters, PreferCountWhere, PreferKeyPath, PreferSwiftTesting, RedundantFileprivate, RedundantNilInit, RedundantOptionalBinding, RedundantReturn, RedundantType, RedundantTypedThrows, StrongifiedSelf
- Removed dead code branches (`< "3"`, `< "5.1"`, `< "5.3"`) from: Semicolons, RedundantReturn, AndOperator
- Simplified TrailingCommas: removed `< "6.1"` dead branches, simplified `>= "6.1"` always-true guards, kept `== "6.2"` bug workarounds
- Kept `< "6.4"` guard in RedundantMemberwiseInit (future version)

### FormattingHelpers.swift (8 edits)
- Removed `< "3"` autoclosure dead code
- Simplified `await`/`unsafe` spacing to always true
- Removed `>= "5.4"` redundantSelf guard
- Removed `>= "5.9"` conditional statement guard
- Stubbed out `conditionalBranchHasUnsupportedCastOperator` (Swift 5.9-only bug)
- Simplified implicit self handling (removed `>= "5.3"`, `>= "5.8"` guards)
- Removed `< "4"` lazy dead code
- Removed `< "5"` onlyLocal dead code

### Lint Module (5 edits)
- Simplified runtime checks in PreferKeyPathRule, RedundantSelfRule, UnusedImportRule, LintableFilesVisitor
- Changed default minSwiftVersion from .five to .sixDotTwo
- Changed SwiftVersion fallback from .five to .sixDotTwo

### SwiftFormat.swift
- Trimmed swiftVersions to ["6.2", "6.3", "6.4"]
- Trimmed languageModes to ["6"]
- Simplified defaultLanguageMode to always return "6"

### Config.swift
- Added validation: clamps configured swiftVersion to >= 6.2
