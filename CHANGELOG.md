# Changelog

## Week of Apr 6 – Apr 12, 2026

### ✨ Features

- Inline suppression comments ([#166](https://github.com/toba/swiftiomatic/issues/166))
- Config and inline comment migration tool ([#165](https://github.com/toba/swiftiomatic/issues/165))
- Nested per-directory configuration ([#169](https://github.com/toba/swiftiomatic/issues/169))
- Add `dump-config` CLI subcommand to show resolved configuration
- Support file-level `sm:disable:file` scope

### 🐛 Fixes

- Fix 7 test failures in Swiftiomatic test suite ([#126](https://github.com/toba/swiftiomatic/issues/126))
- Xcode cannot compile swiftiomatic; module resolution failure due to case-insensitive FS collision
- Config file selected via file importer not loaded into app
- `redundant_sendable`; detect redundant conformance in public extension context

### 🗜️ Tweaks

- Setup brew installation within existing toba tap ([#171](https://github.com/toba/swiftiomatic/issues/171))
- Build `assertLint`/`assertFormatting` test infrastructure ([#168](https://github.com/toba/swiftiomatic/issues/168))
- Adopt Apple `swift-format` test patterns for comprehensive rule coverage ([#162](https://github.com/toba/swiftiomatic/issues/162))
- Swift review; modernization, shared code, performance ([#172](https://github.com/toba/swiftiomatic/issues/172))
- Get Xcode Source Editor Extension working as plugin ([#174](https://github.com/toba/swiftiomatic/issues/174))
- Swiftiomatic; AST-based Swift code analysis CLI ([#59](https://github.com/toba/swiftiomatic/issues/59))
- Migrate remaining 44 test files to `swift-format` assert pattern ([#175](https://github.com/toba/swiftiomatic/issues/175))
- Sanitize rules; consolidate, eliminate, or split overlapping rules
- Unify version number across CLI, app, and extension ([#176](https://github.com/toba/swiftiomatic/issues/176))
- Modernize `macOSSDKPath()` from `Process` to `Subprocess`
- Rename `SwiftiomaticKit` enum to avoid shadowing module name
- Review upstream SwiftLint, SwiftFormat, and swift-format releases
- Clean up test infrastructure from Swift review
