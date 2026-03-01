---
# ivk-5u2
title: Fix all build errors and test failures for CLI and Xcode app
status: completed
type: bug
priority: normal
created_at: 2026-03-01T20:06:13Z
updated_at: 2026-03-01T20:53:39Z
sync:
    github:
        issue_number: "125"
        synced_at: "2026-03-01T21:06:26Z"
---

## Context
After ViolationSeverity→Severity rename and BridgeExtensions.swift deletion, the CLI (SwiftiomaticCLI) and Xcode app (SwiftiomaticApp) have build errors. 54 errors visible in Xcode — mostly 'Cannot find X in scope' due to `package` access types not being visible to the CLI target, plus cascading issues when naively changing `package` → `public`.

## Problems
1. CLI target cannot see `package`-level types from Swiftiomatic module
2. Changing to `public` causes cascading errors (types used in public API that are still `package`)
3. `FileHandle+TextOutputStream` conformance not visible across modules
4. Stale DerivedData causing phantom errors
5. Pre-existing test failures (7 reported in prior issue)

## Tasks
- [x] Determine root cause of CLI visibility issue (access levels vs module structure vs InternalImportsByDefault)
- [x] Fix all CLI build errors
- [x] Fix all Xcode app build errors  
- [x] Fix all test failures
- [x] Verify clean build for both CLI and app


## Summary of Changes

### Root cause
`package` access on ~80 declarations prevented CLI/Xcode targets from seeing Swiftiomatic types.

### Fixes applied
1. Bulk `package` → `public` via sed for structs, classes, enums, protocols, funcs, vars, lets, etc.
2. Added `Sendable` conformance to `RuleViolation`, `LinterCache`, `FormatRuleCatalog`, and internal cache types.
3. Made `SwiftVersion` static properties public (needed for public default arguments).
4. Added `public import Foundation` where needed for public protocol conformances.
5. Restored `BridgeExtensions.swift` (was incorrectly deleted while still referenced).
6. Fixed `RuleSelection` to exclude `.format` and `.suggest` scope rules from default lint config.
7. Fixed `Command.init` to trim `\r` from carriage-return line endings.
8. Fixed `PeriodSpacingRule` regex (`[^\S\r\n]` → `[ \t]`) to avoid Swift Regex engine mismatch.
9. Added SwiftSyntax-based comment/string range fallback in `SwiftSource+Matching` for when SourceKit is disabled.
10. Fixed test helper two-pass collect-then-validate for `CollectingRule` tests.

### Results
- `swift build --build-tests`: zero errors
- Xcode build: zero errors
- `swift test`: 4535 passed, 0 failed
