---
# jjv-3ri
title: Incorporate SwiftFormat into Swiftiomatic
status: completed
type: feature
priority: normal
created_at: 2026-02-27T22:25:36Z
updated_at: 2026-02-27T22:55:11Z
---

Add a format subcommand by copying SwiftFormat engine into a new Formatting target.

## Tasks
- [x] Phase 1: Copy core engine into Sources/Formatting/
- [x] Phase 2: Swift 6.2 concurrency refactoring
- [x] Phase 3: Write FormatEngine.swift public API
- [x] Phase 4: Add format subcommand to CLI
- [x] Phase 5: YAML configuration support
- [x] Phase 6: Package.swift changes
- [x] Phase 7: Licensing & citations


## Summary of Changes

Copied SwiftFormat engine (138 rules) into Sources/Formatting/ target with zero external dependencies. Refactored for Swift 6.2 strict concurrency (removed NSObject inheritance, added @unchecked Sendable/nonisolated(unsafe) annotations, replaced GCD timeout with sequential rule application). Created FormatEngine public API, format CLI subcommand with --check/--config/--enable/--disable/--list-rules, YAML config support via Yams, and MIT license attribution.
