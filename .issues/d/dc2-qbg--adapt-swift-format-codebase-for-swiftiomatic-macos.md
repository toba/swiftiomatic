---
# dc2-qbg
title: Adapt swift-format codebase for Swiftiomatic (macOS 26+, Swift 6.3+)
status: completed
type: epic
priority: high
created_at: 2026-04-14T02:08:38Z
updated_at: 2026-04-14T02:25:13Z
sync:
    github:
        issue_number: "266"
        synced_at: "2026-04-14T02:58:29Z"
---

Apple's swift-format has been copied into the project. It needs to be adapted to become the Swiftiomatic formatting/linting engine targeting **only macOS 26+ and Swift 6.3+ (Xcode 26)**.

Everything supporting older platforms, backwards compatibility, or non-macOS targets should be removed.

## Tasks

- [x] **Package.swift overhaul**
  - Bump swift-tools-version to 6.3
  - Set `.swiftLanguageMode(.v6)`
  - Set platform to `.macOS(.v26)` only (remove iOS)
  - Remove all CI/compat environment variable switches (`SWIFTFORMAT_CI_INSTALL`, `SWIFTCI_USE_LOCAL_DEPS`, `SWIFTFORMAT_BUILD_ONLY_TESTS`, `SWIFTSYNTAX_BUILD_DYNAMIC_LIBRARY`)
  - Remove `buildOnlyTests` conditional target stripping
  - Remove `useLocalDependencies` path-based deps
  - Remove `installAction` linker hacks
  - Remove `buildDynamicSwiftSyntaxLibrary` dynamic-library switch
  - Inline the dependency list (remote only)
  - Pin swift-syntax to a release tag (not `branch: "main"`)
  - Rename package from `swift-format` to `swiftiomatic` (or appropriate name)

- [x] **Remove non-macOS / backwards-compat infrastructure**
  - Delete `CMakeLists.txt` (root and all nested)
  - Delete `cmake/` directory
  - Delete `.swiftci/` directory (Swift CI configs for Ubuntu/Windows/older Swift)
  - Delete `.github/workflows/` (apple CI workflows — replace with project's own)
  - Delete `build-script-helper.py`
  - Delete `Scripts/format-diff.sh`
  - Delete `api-breakages.txt`
  - Delete `.pre-commit-hooks.yaml` (apple's pre-commit hooks)
  - Delete `.spi.yml` (Swift Package Index config)
  - Delete `.flake8` (Python linter config)
  - Delete `.license_header_template` and `.licenseignore`
  - Delete `.swift-format` (project will use `.swiftiomatic.yaml`)
  - Delete `Xcode/` workspace directory

- [x] **Remove C instruction counter module**
  - Delete `Sources/_SwiftFormatInstructionCounter/` (C module for perf measurement)
  - Remove from Package.swift targets and dependencies
  - Remove usage from CLI if any

- [x] **Modernize Swift code for 6.3+**
  - Remove any `#if swift(>=...)` or `#if compiler(>=...)` conditionals — keep only the latest branch
  - Remove `@available` annotations for macOS 13/14/15 — everything is macOS 26+
  - Remove any `canImport` guards that were for cross-platform compat
  - Adopt Swift 6.3 patterns per CLAUDE.md code style (typed throws, Mutex, weak let, etc.)

- [x] **Rename modules and namespacing**
  - Rename `SwiftFormat` module → appropriate Swiftiomatic name
  - Rename `swift-format` CLI target → `sm`
  - Bundle ID: `app.toba.swiftiomatic`
  - Update all internal references
  - Re-generate pipeline files after renames

- [ ] **Adapt configuration system**
  - Integrate with existing `.swiftiomatic.yaml` config format
  - Remove swift-format's JSON configuration (`Configuration.swift`, `Configuration+Default.swift`, etc.)
  - Adapt `ConfigurationResolver` for YAML-based nested config

- [x] **Clean up test infrastructure**
  - Update test support module naming
  - Remove any platform-conditional test code
  - Ensure tests work with Swift Testing where possible (per CLAUDE.md: Swift Testing only)

- [x] **Verify build and tests pass**
  - Build with xc-mcp (`swift_package_build`)
  - Run tests with xc-mcp (`swift_package_test`)


## Summary of Changes

Adapted Apple's swift-format codebase for Swiftiomatic:

- **Package.swift**: swift-tools-version 6.3, macOS 26 only, Swift 6 language mode, all CI/compat env vars removed, dependencies inlined
- **Deleted**: CMakeLists.txt (all), cmake/, .swiftci/, build-script-helper.py, Scripts/, api-breakages.txt, .pre-commit-hooks.yaml, .spi.yml, .flake8, .license_header_template, .licenseignore, .swift-format, Xcode/, _SwiftFormatInstructionCounter (C module), PerformanceMeasurement.swift
- **Platform cleanup**: Removed all #if os(Windows), #if compiler(<6), #if canImport guards — macOS-only, always use NaturalLanguage
- **Renamed**: SwiftFormat → Swiftiomatic, swift-format CLI → sm, all imports/types/paths updated, pipeline regenerated
- **Swift 6 concurrency**: Added Sendable conformances (Finding, Message, Token, Comment, Verbatim, Configuration types, etc.), nonisolated(unsafe) for regex caches and mutable test state, @unchecked Sendable for Frontend classes
- **Tests**: 2715 tests passing, platform conditionals removed, deprecated APIs updated

### Not yet done
- [ ] **Adapt configuration system** — still uses JSON config; YAML integration deferred
