# Changelog

## Week of Apr 6 – Apr 12, 2026

### ✨ Features

- Inline suppression comments ([#166](https://github.com/toba/swiftiomatic/issues/166))
- Config and inline comment migration tool ([#165](https://github.com/toba/swiftiomatic/issues/165))
- Nested per-directory configuration ([#169](https://github.com/toba/swiftiomatic/issues/169))
- Add `dump-config` CLI subcommand to show resolved configuration ([#178](https://github.com/toba/swiftiomatic/issues/178))
- Support file-level `sm:disable:file` scope ([#180](https://github.com/toba/swiftiomatic/issues/180))
- `single_line_body` format rule; condense single-statement blocks to one line ([#188](https://github.com/toba/swiftiomatic/issues/188))

### 🐛 Fixes

- Fix 7 test failures in Swiftiomatic test suite ([#126](https://github.com/toba/swiftiomatic/issues/126))
- Xcode cannot compile swiftiomatic; module resolution failure due to case-insensitive FS collision ([#173](https://github.com/toba/swiftiomatic/issues/173))
- Config file selected via file importer not loaded into app ([#184](https://github.com/toba/swiftiomatic/issues/184))
- `redundant_sendable`; detect redundant conformance in public extension context ([#177](https://github.com/toba/swiftiomatic/issues/177))
- Release workflow fails; `macos-15` runner lacks Swift 6.3 / Xcode 26 ([#190](https://github.com/toba/swiftiomatic/issues/190))
- Fix 11 rule bugs surfaced by pipeline regeneration and test coverage

### 🗜️ Tweaks

- Setup brew installation within existing toba tap ([#171](https://github.com/toba/swiftiomatic/issues/171))
- Build `assertLint`/`assertFormatting` test infrastructure ([#168](https://github.com/toba/swiftiomatic/issues/168))
- Adopt Apple `swift-format` test patterns for comprehensive rule coverage ([#162](https://github.com/toba/swiftiomatic/issues/162))
- Swift review; modernization, shared code, performance ([#172](https://github.com/toba/swiftiomatic/issues/172))
- Get Xcode Source Editor Extension working as plugin ([#174](https://github.com/toba/swiftiomatic/issues/174))
- Swiftiomatic; AST-based Swift code analysis CLI ([#59](https://github.com/toba/swiftiomatic/issues/59))
- Migrate remaining 44 test files to `swift-format` assert pattern ([#175](https://github.com/toba/swiftiomatic/issues/175))
- Sanitize rules; consolidate, eliminate, or split overlapping rules ([#183](https://github.com/toba/swiftiomatic/issues/183))
- Unify version number across CLI, app, and extension ([#176](https://github.com/toba/swiftiomatic/issues/176))
- Modernize `macOSSDKPath()` from `Process` to `Subprocess` ([#186](https://github.com/toba/swiftiomatic/issues/186))
- Rename `SwiftiomaticKit` enum to avoid shadowing module name ([#187](https://github.com/toba/swiftiomatic/issues/187))
- Review upstream SwiftLint, SwiftFormat, and swift-format releases ([#185](https://github.com/toba/swiftiomatic/issues/185))
- Improve rule summaries; fill empty `static let summary` fields ([#181](https://github.com/toba/swiftiomatic/issues/181))
- Clean up test infrastructure from Swift review ([#179](https://github.com/toba/swiftiomatic/issues/179))
- Add test job to CI; gate Homebrew update on tests passing ([#191](https://github.com/toba/swiftiomatic/issues/191))
- Standardize rule names for consistency ([#189](https://github.com/toba/swiftiomatic/issues/189))
- Rename CLI binary from `swiftiomatic` to `sm` ([#192](https://github.com/toba/swiftiomatic/issues/192))
- Populate missing rule examples for parameterized testing ([#193](https://github.com/toba/swiftiomatic/issues/193))
